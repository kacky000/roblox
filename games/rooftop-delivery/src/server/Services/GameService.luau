--!strict
-- コアループ（屋上から屋上へ荷物を届けるタイムアタック）のサーバー権威ロジック
-- 配達先の決定・到着の判定・タイム・報酬はすべてサーバーが行う。クライアントは目印を表示するだけ
-- 数値は Config/GameConfig.luau

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Delivery = require(Shared.Lib.Delivery)
local Economy = require(Shared.Lib.Economy)
local RateLimiter = require(Shared.Lib.RateLimiter)
local Net = require(Shared.Net)

local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local CityBuilder = require(script.Parent.Parent.City.CityBuilder)
local CityData = require(script.Parent.Parent.City.CityData) :: any

local GameService = {}

type Job = {
	from: number,
	target: number,
	startedAt: number,
	distance: number,
	par: number,
	streak: number,
}

local rng = Random.new()
local function nextNumber(): number
	return rng:NextNumber()
end

local actionLimiter = RateLimiter.new(8, 16)

local DataChanged = Net.event("DataChanged")
local Notify = Net.event("Notify")
local JobChanged = Net.event("JobChanged")
local JobDone = Net.event("JobDone")

local roofs: { Delivery.Roof } = Delivery.roofs(CityData.buildings, GameConfig.Roofs)
local depot: number = 1
local jobs: { [Player]: Job } = {}

local function upgradeLevel(data: any, id: string): number
	local def = GameConfig.Upgrades[id]
	return math.clamp(data.upgrades[id] or 0, 0, def.maxLevel)
end

-- 強化を全部積んだときの速さ × 余裕。これより速い到着は報酬を出さない
local function maxPlausibleSpeed(): number
	local up = GameConfig.Upgrades.Speed
	return (GameConfig.Movement.walkSpeed + up.maxLevel * up.effectPerLevel)
		* GameConfig.Delivery.plausibleSpeedMargin
end

local function push(player: Player)
	local d = DataService.get(player)
	if not d then
		return
	end
	DataChanged:FireClient(player, {
		coins = d.coins,
		upgrades = d.upgrades,
		deliveries = d.delivery.total,
		bestStreak = d.delivery.bestStreak,
	})
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls:FindFirstChild("Deliveries") :: IntValue).Value = d.delivery.total;
		(ls:FindFirstChild("Coins") :: IntValue).Value = d.coins
		local job = jobs[player];
		(ls:FindFirstChild("Streak") :: IntValue).Value = if job then job.streak else 0
	end
end

local function applyMovement(player: Player)
	local d = DataService.get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not d or not humanoid then
		return
	end
	local m, up = GameConfig.Movement, GameConfig.Upgrades
	humanoid.UseJumpPower = false
	humanoid.WalkSpeed = m.walkSpeed + upgradeLevel(d, "Speed") * up.Speed.effectPerLevel
	humanoid.JumpHeight = m.jumpHeight + upgradeLevel(d, "Jump") * up.Jump.effectPerLevel
end

local function assign(player: Player, from: number, streak: number)
	local target = Delivery.nextTarget(
		roofs,
		from,
		GameConfig.Delivery.minDistance,
		GameConfig.Delivery.maxDistance,
		nextNumber
	)
	if not target then
		return
	end
	local a, b = roofs[from], roofs[target]
	local dist = Delivery.horizontalDistance(a, b)
	local par = Delivery.parSeconds(dist, b.y - a.y, GameConfig.Delivery.par)
	jobs[player] = {
		from = from,
		target = target,
		startedAt = os.clock(),
		distance = dist,
		par = par,
		streak = streak,
	}
	JobChanged:FireClient(player, { x = b.x, y = b.y, z = b.z, par = par, streak = streak, distance = dist })
end

local function complete(player: Player, job: Job)
	local elapsed = os.clock() - job.startedAt
	if not Delivery.isPlausible(elapsed, job.distance, maxPlausibleSpeed()) then
		-- 速すぎる到着（瞬間移動など）は数えない。同じ屋上から別の配達をやり直す
		assign(player, job.target, 0)
		return
	end
	local streak = Delivery.nextStreak(job.streak, elapsed, job.par)
	local mult = MonetizationService.perk(player, "rewardMultiplier", 1)
	local coins = Delivery.reward(job.distance, streak, mult, GameConfig.Delivery.reward)
	DataService.update(player, function(d)
		d.coins += coins
		d.stats.totalEarned += coins
		d.delivery.total += 1
		d.delivery.bestStreak = math.max(d.delivery.bestStreak, streak)
	end)
	JobDone:FireClient(player, { elapsed = elapsed, par = job.par, coins = coins, streak = streak })
	assign(player, job.target, streak)
	push(player)
end

local function checkArrivals()
	local cfg = GameConfig.Delivery
	for player, job in jobs do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local roof = roofs[job.target]
			local p = root.Position
			local dx, dz = p.X - roof.x, p.Z - roof.z
			local dy = p.Y - roof.y
			if
				dx * dx + dz * dz <= cfg.touchRadius * cfg.touchRadius
				and dy >= -1
				and dy <= cfg.touchHeight
			then
				complete(player, job)
			end
		end
	end
end

local function buildGround(folder: Instance)
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, row in CityData.buildings do
		for i = 2, #row - 1, 2 do
			minX, maxX = math.min(minX, row[i]), math.max(maxX, row[i])
			minZ, maxZ = math.min(minZ, row[i + 1]), math.max(maxZ, row[i + 1])
		end
	end
	local margin = GameConfig.City.groundMargin
	minX, maxX, minZ, maxZ = minX - margin, maxX + margin, minZ - margin, maxZ + margin
	local tile = 1024 -- Part の一辺の上限（2048）より小さく分ける
	local x = minX
	while x < maxX do
		local w = math.min(tile, maxX - x)
		local z = minZ
		while z < maxZ do
			local d = math.min(tile, maxZ - z)
			local ground = Instance.new("Part")
			ground.Name = "Ground"
			ground.Anchored = true
			ground.Size = Vector3.new(w, 2, d)
			ground.Position = Vector3.new(x + w / 2, -1, z + d / 2)
			ground.Color = Color3.fromRGB(120, 124, 130)
			ground.Material = Enum.Material.Concrete
			ground.TopSurface = Enum.SurfaceType.Smooth
			ground.Parent = folder
			z += d
		end
		x += w
	end
end

local function buildCity()
	local folder = Instance.new("Folder")
	folder.Name = "City"
	folder.Parent = Workspace

	buildGround(folder)

	-- 出発点（集配所）は街の中心に一番近い屋上
	local cx, cz = Delivery.center(roofs)
	depot = Delivery.nearest(roofs, cx, cz) or 1
	local roof = roofs[depot]
	if roof then
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Depot"
		spawn.Anchored = true
		spawn.Size = Vector3.new(12, 1, 12)
		spawn.Position = Vector3.new(roof.x, roof.y + 0.5, roof.z)
		spawn.Color = Color3.fromRGB(255, 196, 64)
		spawn.Material = Enum.Material.SmoothPlastic
		spawn.TopSurface = Enum.SurfaceType.Smooth
		spawn.Neutral = true
		spawn.Parent = folder
	end

	local stats = CityBuilder.build(CityData, folder, {
		yieldEvery = GameConfig.City.yieldEvery,
		minRoadWidth = GameConfig.City.minRoadWidth,
	})
	print(`[GameService] city built: {stats.total} parts, {#roofs} delivery roofs`)
end

local function onLoaded(player: Player, _data: any)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, name in { "Deliveries", "Streak", "Coins" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = ls
	end
	ls.Parent = player

	player.CharacterAdded:Connect(function()
		task.defer(applyMovement, player)
	end)
	applyMovement(player)

	if #roofs >= 2 then
		assign(player, depot, 0)
	end
	push(player)
end

function GameService.start()
	task.spawn(buildCity)

	DataService.Loaded:Connect(onLoaded)
	Players.PlayerRemoving:Connect(function(p)
		jobs[p] = nil
		actionLimiter:forget(p.UserId)
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt: number)
		acc += dt
		if acc >= GameConfig.Delivery.checkInterval then
			acc = 0
			checkArrivals()
		end
	end)

	Net.onServer("RequestUpgrade", { "string" }, function(player, upgradeId: string)
		if not actionLimiter:allow(player.UserId) then
			return
		end
		local def = GameConfig.Upgrades[upgradeId]
		if not def then
			return
		end
		local bought = false
		DataService.update(player, function(d)
			local owned = d.upgrades[upgradeId] or 0
			if owned >= def.maxLevel then
				return
			end
			local cost = Economy.upgradeCost(def.base, def.growth, owned)
			if d.coins >= cost then
				d.coins -= cost
				d.upgrades[upgradeId] = owned + 1
				bought = true
			end
		end)
		if bought then
			applyMovement(player)
		else
			Notify:FireClient(player, "コインが足りないか、最大レベルです")
		end
		push(player)
	end)
end

return GameService

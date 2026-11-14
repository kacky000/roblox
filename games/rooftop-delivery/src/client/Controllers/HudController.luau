--!strict
-- 最小HUD（コード生成UI）と、配達先の目印（自分にだけ見えるローカルの Part）
-- 到着の判定とタイムの確定はサーバーが行う。ここのタイマーは表示用
-- モバイル比率が高いので: ボタンは大きく(>=44px相当)、画面下部に配置、Scaleベースで配置

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Delivery = require(Shared.Lib.Delivery)
local Economy = require(Shared.Lib.Economy)
local GameConfig = require(Shared.Config.GameConfig)
local Net = require(Shared.Net)

local HudController = {}

local function make(className: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function button(parent: Instance, text: string, pos: UDim2, color: Color3, onClick: () -> ())
	local b = make("TextButton", {
		Size = UDim2.fromScale(0.22, 0.09),
		Position = pos,
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = color,
		Text = text,
		TextScaled = true,
		Font = Enum.Font.FredokaOne,
		TextColor3 = Color3.new(1, 1, 1),
	}, parent)
	make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, b)
	make(
		"UIStroke",
		{ Thickness = 3, Color = Color3.fromRGB(30, 30, 50), ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
		b
	)
	make("UIAspectRatioConstraint", { AspectRatio = 2.6 }, b)
	b.Activated:Connect(function()
		local s = b.Size
		TweenService
			:Create(b, TweenInfo.new(0.06), { Size = UDim2.fromScale(s.X.Scale * 0.92, s.Y.Scale * 0.92) })
			:Play()
		task.delay(0.06, function()
			TweenService:Create(b, TweenInfo.new(0.1, Enum.EasingStyle.Back), { Size = s }):Play()
		end)
		onClick()
	end)
	return b
end

local function label(parent: Instance, size: UDim2, pos: UDim2, color: Color3): TextLabel
	local l = make("TextLabel", {
		Size = size,
		Position = pos,
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextScaled = true,
		Font = Enum.Font.FredokaOne,
		TextColor3 = color,
	}, parent)
	make("UIStroke", { Thickness = 3 }, l)
	return l
end

-- 配達先の目印：屋上の円盤、空まで伸びる光の柱、距離の表示
local function makeMarker(): (Part, TextLabel)
	local pad = make("Part", {
		Name = "DeliveryTarget",
		Shape = Enum.PartType.Cylinder,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 196, 64),
		Transparency = 0.3,
		Size = Vector3.new(0.6, GameConfig.Delivery.touchRadius * 2, GameConfig.Delivery.touchRadius * 2),
	})
	make("Part", {
		Name = "Beam",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 196, 64),
		Transparency = 0.6,
		Size = Vector3.new(3, 600, 3),
	}, pad)
	local billboard = make("BillboardGui", {
		Size = UDim2.fromOffset(160, 50),
		StudsOffset = Vector3.new(0, 14, 0),
		AlwaysOnTop = true,
		MaxDistance = 5000,
	}, pad)
	local text = make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		TextScaled = true,
		Font = Enum.Font.FredokaOne,
		TextColor3 = Color3.fromRGB(255, 230, 140),
	}, billboard)
	make("UIStroke", { Thickness = 2 }, text)
	return pad, text
end

function HudController.start()
	local player = Players.LocalPlayer
	local gui = make(
		"ScreenGui",
		{ Name = "HUD", ResetOnSpawn = false, IgnoreGuiInset = false },
		player:WaitForChild("PlayerGui")
	)

	local coinLabel =
		label(gui, UDim2.fromScale(0.3, 0.07), UDim2.fromScale(0.5, 0.02), Color3.fromRGB(255, 220, 80))
	coinLabel.Text = "🪙 0"
	local timerLabel = label(gui, UDim2.fromScale(0.4, 0.06), UDim2.fromScale(0.5, 0.1), Color3.new(1, 1, 1))
	local streakLabel =
		label(gui, UDim2.fromScale(0.3, 0.04), UDim2.fromScale(0.5, 0.165), Color3.fromRGB(255, 160, 90))
	local toast = label(gui, UDim2.fromScale(0.6, 0.06), UDim2.fromScale(0.5, 0.22), Color3.new(1, 1, 1))
	toast.TextTransparency = 1

	-- データのクレジット（ODbL の表示義務）
	make("TextLabel", {
		Size = UDim2.fromScale(0.3, 0.025),
		Position = UDim2.fromScale(0.005, 0.995),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Text = GameConfig.City.attribution,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = 0.3,
	}, gui)

	local function showToast(msg: string)
		toast.Text = msg
		toast.TextTransparency = 0
		TweenService:Create(toast, TweenInfo.new(3), { TextTransparency = 1 }):Play()
	end

	local speedBtn = button(
		gui,
		"スピード",
		UDim2.fromScale(0.36, 0.96),
		Color3.fromRGB(90, 160, 255),
		function()
			Net.event("RequestUpgrade"):FireServer("Speed")
		end
	)
	local jumpBtn = button(
		gui,
		"ジャンプ",
		UDim2.fromScale(0.64, 0.96),
		Color3.fromRGB(80, 200, 120),
		function()
			Net.event("RequestUpgrade"):FireServer("Jump")
		end
	)

	local function upgradeText(name: string, id: string, upgrades: { [string]: number }): string
		local def = GameConfig.Upgrades[id]
		local owned = upgrades[id] or 0
		if owned >= def.maxLevel then
			return `{name} MAX`
		end
		return `{name} Lv{owned + 1} ({Economy.abbreviate(Economy.upgradeCost(def.base, def.growth, owned))})`
	end

	Net.event("DataChanged").OnClientEvent:Connect(function(d)
		coinLabel.Text = "🪙 " .. Economy.abbreviate(d.coins)
		speedBtn.Text = upgradeText("スピード", "Speed", d.upgrades)
		jumpBtn.Text = upgradeText("ジャンプ", "Jump", d.upgrades)
	end)

	Net.event("Notify").OnClientEvent:Connect(showToast)

	-- 配達の状態
	local marker, distanceText = makeMarker()
	local target: Vector3? = nil
	local startedAt = 0
	local par = 0

	Net.event("JobChanged").OnClientEvent:Connect(function(job)
		local pos = Vector3.new(job.x, job.y, job.z)
		target = pos
		startedAt = os.clock()
		par = job.par
		marker.CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		local beam = marker:FindFirstChild("Beam")
		if beam and beam:IsA("BasePart") then
			beam.CFrame = CFrame.new(pos + Vector3.new(0, 300, 0))
		end
		marker.Parent = Workspace
		streakLabel.Text = if job.streak > 0 then `🔥 連続 {job.streak}` else ""
	end)

	Net.event("JobDone").OnClientEvent:Connect(function(result)
		local time = Delivery.formatTime(result.elapsed)
		if result.streak > 0 then
			showToast(`配達完了！ {time}（目標内）+{result.coins}🪙  連続 {result.streak}`)
		else
			showToast(`配達完了 {time}（目標 {Delivery.formatTime(result.par)}）+{result.coins}🪙`)
		end
	end)

	RunService.RenderStepped:Connect(function()
		local goal = target
		if not goal then
			return
		end
		local elapsed = os.clock() - startedAt
		timerLabel.Text = `⏱ {Delivery.formatTime(elapsed)} / {Delivery.formatTime(par)}`
		timerLabel.TextColor3 = if elapsed <= par then Color3.new(1, 1, 1) else Color3.fromRGB(255, 120, 120)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			distanceText.Text = `📦 {math.floor((root.Position - goal).Magnitude)}`
		end
	end)
end

return HudController

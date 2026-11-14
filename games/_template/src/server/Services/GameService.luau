--!strict
-- コアループ（放置収益・アップグレード・リバース・卵ガチャ）のサーバー権威ロジック
-- ゲームごとにここを差し替える。数値は Config/GameConfig.luau

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Economy = require(Shared.Lib.Economy)
local WeightedRandom = require(Shared.Lib.WeightedRandom)
local RateLimiter = require(Shared.Lib.RateLimiter)
local Net = require(Shared.Net)

local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)

local GameService = {}

local rng = Random.new()
local function nextNumber(): number
	return rng:NextNumber()
end

local actionLimiter = RateLimiter.new(8, 16)

-- 有料ランダムアイテム規制（国・年齢で禁止される場合がある）。
-- Robuxで買える通貨を使う卵＝有料ランダムアイテム扱い → 規制ユーザーには販売しない
local randomItemsRestricted: { [Player]: boolean } = {}
local function isRandomRestricted(player: Player): boolean
	local cached = randomItemsRestricted[player]
	if cached ~= nil then
		return cached
	end
	local ok, info = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
	-- 取得失敗時は安全側（規制あり）に倒す
	local restricted = not ok or (info :: any).ArePaidRandomItemsRestricted == true
	randomItemsRestricted[player] = restricted
	return restricted
end
local DataChanged = Net.event("DataChanged")
local Notify = Net.event("Notify")

local function push(player: Player)
	local d = DataService.get(player)
	if not d then
		return
	end
	DataChanged:FireClient(player, {
		coins = d.coins,
		gems = d.gems,
		rebirths = d.rebirths,
		upgrades = d.upgrades,
		inventory = d.inventory,
	})
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls:FindFirstChild("Coins") :: NumberValue).Value = d.coins;
		(ls:FindFirstChild("Rebirths") :: NumberValue).Value = d.rebirths
	end
end

local function boostValue(data: any, name: string): number
	local b = data.boosts and data.boosts[name]
	if b and b.expires > os.time() then
		return b.value
	end
	return 1
end

function GameService.incomePerSecond(player: Player): number
	local d = DataService.get(player)
	if not d then
		return 0
	end
	local cfg = GameConfig.Income
	local upg = (d.upgrades.Income or 0) * GameConfig.Upgrades.Income.effectPerLevel
	local mult = Economy.rebirthMultiplier(d.rebirths, cfg.perRebirth)
		* MonetizationService.perk(player, "incomeMultiplier", 1)
		* boostValue(d, "income")
	return (cfg.basePerSecond + upg) * mult
end

local function onLoaded(player: Player, data: any)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local coins = Instance.new("NumberValue")
	coins.Name = "Coins"
	coins.Parent = ls
	local reb = Instance.new("NumberValue")
	reb.Name = "Rebirths"
	reb.Parent = ls
	ls.Parent = player

	-- オフライン収益
	if data.lastOnline > 0 then
		local away = os.time() - data.lastOnline
		local eff = MonetizationService.perk(player, "offlineEfficiency", GameConfig.OfflineEfficiency)
		local earned = Economy.offlineEarnings(
			GameService.incomePerSecond(player),
			away,
			GameConfig.OfflineCapSeconds,
			eff
		)
		if earned > 0 then
			DataService.update(player, function(d)
				d.coins += earned
			end)
			Notify:FireClient(
				player,
				`おかえり！オフライン中に {Economy.abbreviate(earned)} コイン獲得`
			)
		end
	end
	push(player)
end

function GameService.start()
	DataService.Loaded:Connect(onLoaded)
	Players.PlayerRemoving:Connect(function(p)
		randomItemsRestricted[p] = nil
		actionLimiter:forget(p.UserId)
	end)

	-- 放置収益 tick（1秒）
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local inc = GameService.incomePerSecond(player)
				if inc > 0 then
					DataService.update(player, function(d)
						d.coins += inc
						d.stats.totalEarned += inc
						d.stats.playSeconds += 1
					end)
					push(player)
				end
			end
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
		DataService.update(player, function(d)
			local owned = d.upgrades[upgradeId] or 0
			local cost = Economy.upgradeCost(def.base, def.growth, owned)
			if d.coins >= cost then
				d.coins -= cost
				d.upgrades[upgradeId] = owned + 1
			end
		end)
		push(player)
	end)

	Net.onServer("RequestRebirth", {}, function(player)
		if not actionLimiter:allow(player.UserId, 4) then
			return
		end
		DataService.update(player, function(d)
			local cost = Economy.rebirthCost(GameConfig.Rebirth.base, GameConfig.Rebirth.growth, d.rebirths)
			if d.coins >= cost then
				d.coins = 0
				d.upgrades = {}
				d.rebirths += 1
			end
		end)
		push(player)
	end)

	Net.onServer("RequestRoll", { "string" }, function(player, eggId: string)
		if not actionLimiter:allow(player.UserId) then
			return
		end
		local egg = GameConfig.Eggs[eggId]
		if not egg then
			return
		end
		if isRandomRestricted(player) then
			Notify:FireClient(player, "お住まいの地域ではこの機能を利用できません")
			return
		end
		local resultId: string? = nil
		DataService.update(player, function(d: any)
			if d[egg.currency] < egg.price then
				return
			end
			d[egg.currency] -= egg.price
			local luck = MonetizationService.perk(player, "luck", 1) * boostValue(d, "luck")
			local entry, newPity =
				WeightedRandom.rollWithPity(egg.entries, nextNumber, luck, egg.pity, d.pity[eggId] or 0)
			d.pity[eggId] = newPity
			d.inventory[entry.id] = (d.inventory[entry.id] or 0) + 1
			d.stats.rolls += 1
			resultId = entry.id
		end)
		if resultId then
			Notify:FireClient(player, `{resultId} をゲット！`)
		end
		push(player)
	end)
end

return GameService

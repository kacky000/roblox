--!strict
-- 課金処理（GamePass / DevProduct）
-- ProcessReceipt の鉄則:
--   1) PurchaseId で冪等にする（同じレシートが複数回来ても二重付与しない）
--   2) 付与→保存が終わるまで PurchaseGranted を返さない（失敗時は NotProcessedYet でRobloxが再送）
--   3) プレイヤーがいない/データ未ロードなら NotProcessedYet

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Products = require(Shared.Config.Products)
local DataService = require(script.Parent.DataService)

local MonetizationService = {}

local passCache: { [Player]: { [string]: boolean } } = {}
local productById: { [number]: { name: string, def: Products.DevProduct } } = {}
for name, def in Products.DevProducts do
	if def.id ~= 0 then
		productById[def.id] = { name = name, def = def }
	end
end

function MonetizationService.hasPass(player: Player, passName: string): boolean
	local c = passCache[player]
	if c and c[passName] ~= nil then
		return c[passName]
	end
	local def = Products.GamePasses[passName]
	if not def or def.id == 0 then
		return false
	end
	local ok, owns =
		pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, def.id)
	local result = ok and owns == true
	passCache[player] = passCache[player] or {}
	if ok then
		passCache[player][passName] = result
	end
	return result
end

-- 所持パスから倍率を集計
function MonetizationService.perk(player: Player, perkName: string, default: any): any
	local value = default
	for name, def in Products.GamePasses do
		local v = def.perks[perkName]
		if v ~= nil and MonetizationService.hasPass(player, name) then
			if type(v) == "number" and type(value) == "number" then
				value = math.max(value, v)
			else
				value = v
			end
		end
	end
	return value
end

local function grant(player: Player, def: Products.DevProduct): boolean
	local granted = false
	DataService.update(player, function(data)
		if def.kind == "coins" then
			data.coins += def.amount or 0
			granted = true
		elseif def.kind == "gems" then
			data.gems += def.amount or 0
			granted = true
		elseif def.kind == "boost" then
			local boosts = (data :: any).boosts or {}
			local now = os.time()
			local cur = boosts[def.boost :: string]
			local startAt = if cur and cur.expires > now then cur.expires else now
			boosts[def.boost :: string] =
				{ value = def.value or 1, expires = startAt + (def.minutes or 0) * 60 }
			(data :: any).boosts = boosts
			granted = true
		end
	end)
	return granted
end

function MonetizationService.start()
	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local data = DataService.get(player)
		if not data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if data.purchaseHistory[receipt.PurchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted -- 既に付与済み
		end
		local entry = productById[receipt.ProductId]
		if not entry then
			warn(`[Monetization] unknown product {receipt.ProductId}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local ok, granted = pcall(grant, player, entry.def)
		if not ok or not granted then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		DataService.update(player, function(d)
			d.purchaseHistory[receipt.PurchaseId] = true
		end)
		DataService.saveNow(player) -- 即保存してから Granted
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for name, def in Products.GamePasses do
			if def.id == passId then
				passCache[player] = passCache[player] or {}
				passCache[player][name] = true
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		passCache[p] = nil
	end)
end

return MonetizationService

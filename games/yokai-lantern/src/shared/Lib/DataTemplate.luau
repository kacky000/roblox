--!strict
-- プレイヤーデータのスキーマと移行（純粋関数）
-- ルール: キーを消さない・型を変えない。変える時は VERSION を上げて migrate に手順を追加する

local DataTemplate = {}

DataTemplate.VERSION = 1

export type PlayerData = {
	version: number,
	coins: number,
	gems: number,
	rebirths: number,
	upgrades: { [string]: number },
	inventory: { [string]: number },
	pity: { [string]: number },
	purchaseHistory: { [string]: boolean }, -- ProcessReceipt の冪等性用（PurchaseId）
	lastOnline: number,
	stats: { playSeconds: number, totalEarned: number, rolls: number },
	settings: { music: boolean, sfx: boolean },
}

function DataTemplate.new(): PlayerData
	return {
		version = DataTemplate.VERSION,
		coins = 0,
		gems = 0,
		rebirths = 0,
		upgrades = {},
		inventory = {},
		pity = {},
		purchaseHistory = {},
		lastOnline = 0,
		stats = { playSeconds = 0, totalEarned = 0, rolls = 0 },
		settings = { music = true, sfx = true },
	}
end

-- 欠けているキーをテンプレートで補う（深い階層も）
function DataTemplate.reconcile(data: { [any]: any }, template: { [any]: any })
	for k, v in template do
		if data[k] == nil then
			if type(v) == "table" then
				local copy = {}
				DataTemplate.reconcile(copy, v)
				data[k] = copy
			else
				data[k] = v
			end
		elseif type(v) == "table" and type(data[k]) == "table" and next(v) ~= nil then
			DataTemplate.reconcile(data[k], v)
		end
	end
end

local MIGRATIONS: { [number]: (any) -> () } = {
	-- [1] = function(d) d.newField = d.oldField; d.oldField = nil end, -- v1 -> v2
}

function DataTemplate.migrate(data: any): PlayerData
	local v = data.version or 0
	while v < DataTemplate.VERSION do
		local step = MIGRATIONS[v]
		if step then
			step(data)
		end
		v += 1
	end
	data.version = DataTemplate.VERSION
	DataTemplate.reconcile(data, DataTemplate.new() :: any)
	return data
end

-- 購入履歴の肥大化防止（DataStore 4MB 上限対策）。古いものから削る
function DataTemplate.trimPurchaseHistory(data: PlayerData, maxEntries: number)
	local keys = {}
	for k in data.purchaseHistory do
		table.insert(keys, k)
	end
	if #keys <= maxEntries then
		return
	end
	table.sort(keys)
	for i = 1, #keys - maxEntries do
		data.purchaseHistory[keys[i]] = nil
	end
end

return DataTemplate

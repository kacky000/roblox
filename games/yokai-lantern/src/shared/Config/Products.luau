--!strict
-- 課金アイテム定義。ID は Creator Hub（Monetization）で作成後に差し替える
-- GamePass = 買い切り（永続効果）、DevProduct = 消費型（何度でも買える）

export type GamePass = { id: number, perks: { [string]: any } }
export type DevProduct = {
	id: number,
	kind: "coins" | "gems" | "boost",
	amount: number?,
	boost: string?,
	minutes: number?,
	value: number?,
}

local Products = {}

Products.GamePasses = {
	VIP = { id = 0, perks = { incomeMultiplier = 1.5, chatTag = true } },
	DoubleLuck = { id = 0, perks = { luck = 2 } },
	AutoCollect = { id = 0, perks = { autoCollect = true } },
	FullOffline = { id = 0, perks = { offlineEfficiency = 1.0 } },
} :: { [string]: GamePass }

-- 付与処理は server/Services/MonetizationService.luau の grant()（サーバーのみ）
-- 価格はハードコードせず MarketplaceService:GetProductInfo で取得して表示する（Managed Pricing / 地域価格に追従）
Products.DevProducts = {
	Coins1K = { id = 0, kind = "coins", amount = 1_000 },
	Coins10K = { id = 0, kind = "coins", amount = 12_000 }, -- まとめ買いはお得に
	Gems100 = { id = 0, kind = "gems", amount = 100 },
	Luck15m = { id = 0, kind = "boost", boost = "luck", minutes = 15, value = 2 },
} :: { [string]: DevProduct }

return Products

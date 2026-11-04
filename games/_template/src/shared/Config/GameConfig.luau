--!strict
-- ゲームバランスの単一の真実（Single Source of Truth）
-- 数値調整は原則ここだけを触る。AIに調整させる時もこのファイルを対象にする

local GameConfig = {}

GameConfig.DataStoreName = "PlayerData_v1" -- 本番公開後は名前を変えない（変えると全データが消えたように見える）
GameConfig.AutosaveSeconds = 60
GameConfig.OfflineCapSeconds = 8 * 60 * 60
GameConfig.OfflineEfficiency = 0.5

GameConfig.Income = {
	basePerSecond = 1,
	perRebirth = 0.5, -- リバース1回ごとに +50%
}

GameConfig.Upgrades = {
	Speed = { base = 25, growth = 1.15, effectPerLevel = 0.1 },
	Income = { base = 50, growth = 1.12, effectPerLevel = 1 },
}

GameConfig.Rebirth = { base = 10_000, growth = 3.0 }

GameConfig.Eggs = {
	BasicEgg = {
		price = 100,
		currency = "coins",
		pity = { minRarity = 3, threshold = 50 },
		entries = {
			{ id = "Blob", weight = 60, rarity = 0 },
			{ id = "Puff", weight = 30, rarity = 1 },
			{ id = "Sprout", weight = 8, rarity = 2 },
			{ id = "Crystal", weight = 1.9, rarity = 3 },
			{ id = "Golden", weight = 0.1, rarity = 4 },
		},
	},
}

return GameConfig

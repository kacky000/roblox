--!strict
-- ゲームバランスの単一の真実（Single Source of Truth）
-- 数値調整は原則ここだけを触る。AIに調整させる時もこのファイルを対象にする

local GameConfig = {}

GameConfig.DataStoreName = "YokaiLantern_v1" -- 本番公開後は名前を変えない（変えると全データが消えたように見える）
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

-- 昼夜サイクル（このゲームの核）。昼 3 分 → 夜 1 分半。夜は妖怪を誘いやすい
GameConfig.DayNight = { daySeconds = 180, nightSeconds = 90, nightLuck = 3 }

-- 提灯で妖怪を誘う（ガチャ）。妖怪の名前は伝承のもの、見た目はオリジナルで作る
GameConfig.Eggs = {
	Lantern = {
		price = 100,
		currency = "coins",
		pity = { minRarity = 3, threshold = 50 },
		entries = {
			{ id = "Kodama", weight = 60, rarity = 0 },
			{ id = "Chochin", weight = 30, rarity = 1 },
			{ id = "Kappa", weight = 8, rarity = 2 },
			{ id = "Kitsune", weight = 1.9, rarity = 3 },
			{ id = "Ryu", weight = 0.1, rarity = 4 },
		},
	},
}

return GameConfig

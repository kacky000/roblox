--!strict
-- ゲームバランスの単一の真実（Single Source of Truth）
-- 数値調整は原則ここだけを触る。AIに調整させる時もこのファイルを対象にする

local GameConfig = {}

GameConfig.DataStoreName = "RooftopDelivery_v1" -- 本番公開後は名前を変えない（変えると全データが消えたように見える）
GameConfig.AutosaveSeconds = 60

-- 移動（屋上を跳び移れる強さにする。値は Studio で要調整）
GameConfig.Movement = {
	walkSpeed = 32,
	jumpHeight = 75,
}

GameConfig.Upgrades = {
	Speed = { base = 60, growth = 1.35, effectPerLevel = 1.5, maxLevel = 10 },
	Jump = { base = 60, growth = 1.35, effectPerLevel = 4, maxLevel = 10 },
}

-- 配達先に使う屋上の条件（studs。1 stud = 0.28 m）
GameConfig.Roofs = {
	minArea = 600,
	minHeight = 20,
	maxHeight = 110,
}

GameConfig.Delivery = {
	minDistance = 160,
	maxDistance = 420,
	touchRadius = 10, -- 配達先の中心からの水平距離
	touchHeight = 12, -- 屋上からの高さの許容
	checkInterval = 0.1,
	plausibleSpeedMargin = 2.5, -- 最大速度の何倍までを正当とみなすか（落下や跳躍の加速を見込む）
	par = { runSpeed = 24, climbSpeed = 20, baseSeconds = 4 },
	reward = { base = 10, perStud = 0.1, streakBonus = 0.1, streakCap = 10 },
}

-- 街の組み立て
GameConfig.City = {
	yieldEvery = 400,
	minRoadWidth = 8, -- 細い歩道は作らない（Part 数を減らす）
	groundMargin = 200,
	attribution = "Map data © OpenStreetMap contributors (ODbL)",
}

return GameConfig

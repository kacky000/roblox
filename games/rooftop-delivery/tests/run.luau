--!strict
-- Lune で純粋ロジックをテストする:  lune run tests/run.luau
-- （Roblox API に依存しない src/shared/Lib のみ対象。サービスは Studio / Open Cloud Luau Execution で検証）

local Economy = require("../src/shared/Lib/Economy")
local WeightedRandom = require("../src/shared/Lib/WeightedRandom")
local RateLimiter = require("../src/shared/Lib/RateLimiter")
local DataTemplate = require("../src/shared/Lib/DataTemplate")
local Delivery = require("../src/shared/Lib/Delivery")
local GameConfig = require("../src/shared/Config/GameConfig")
local CityData = require("../src/server/City/CityData") :: any

local passed, failed = 0, 0
local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
		print("  ✓ " .. name)
	else
		failed += 1
		print("  ✗ " .. name .. "\n      " .. tostring(err))
	end
end
local function eq(a: any, b: any, msg: string?)
	if a ~= b then
		error(`{msg or "expected equal"}: got {a}, want {b}`, 2)
	end
end

-- 再現可能な疑似乱数（LCG）
local function seeded(seed: number): () -> number
	local s = seed
	return function()
		s = (s * 1103515245 + 12345) % 2147483648
		return s / 2147483648
	end
end

print("Economy")
test("upgradeCost grows exponentially", function()
	eq(Economy.upgradeCost(100, 1.15, 0), 100)
	eq(Economy.upgradeCost(100, 1.15, 10), 404)
end)
test("bulkCost equals sum of single costs (within rounding)", function()
	local sum = 0
	for i = 0, 9 do
		sum += 100 * 1.15 ^ i
	end
	eq(Economy.bulkCost(100, 1.15, 0, 10), math.floor(sum))
end)
test("maxAffordable is consistent with bulkCost", function()
	local n = Economy.maxAffordable(100, 1.15, 3, 5000)
	assert(Economy.bulkCost(100, 1.15, 3, n) <= 5000, "n affordable")
	assert(Economy.bulkCost(100, 1.15, 3, n + 1) > 5000, "n+1 not affordable")
end)
test("offlineEarnings caps time", function()
	eq(Economy.offlineEarnings(10, 1e9, 3600, 0.5), 18000)
	eq(Economy.offlineEarnings(10, -5, 3600, 0.5), 0)
end)
test("abbreviate", function()
	eq(Economy.abbreviate(999), "999")
	eq(Economy.abbreviate(1000), "1K")
	eq(Economy.abbreviate(1234), "1.23K")
	eq(Economy.abbreviate(1.5e9), "1.5B")
	eq(Economy.abbreviate(-2500), "-2.5K")
end)

print("WeightedRandom")
local entries = {
	{ id = "C", weight = 90, rarity = 0 },
	{ id = "R", weight = 9, rarity = 2 },
	{ id = "L", weight = 1, rarity = 4 },
}
test("distribution roughly matches weights", function()
	local rng = seeded(42)
	local counts = { C = 0, R = 0, L = 0 }
	for _ = 1, 100000 do
		local e = WeightedRandom.roll(entries, rng)
		counts[e.id] += 1
	end
	assert(math.abs(counts.C / 1000 - 90) < 1.5, `C {counts.C}`)
	assert(math.abs(counts.L / 1000 - 1) < 0.3, `L {counts.L}`)
end)
test("luck 2x makes legendary ~4x more likely", function()
	local odds1 = WeightedRandom.oddsTable(entries, 1)
	local odds2 = WeightedRandom.oddsTable(entries, 2)
	local ratio = odds2.L / odds1.L
	assert(ratio > 3 and ratio < 4.1, `ratio {ratio}`)
end)
test("odds sum to 100", function()
	local s = 0
	for _, p in WeightedRandom.oddsTable(entries, 3) do
		s += p
	end
	assert(math.abs(s - 100) < 1e-9, `sum {s}`)
end)
test("pity guarantees rare within threshold", function()
	local always0 = function()
		return 0
	end -- 常にコモン
	local pity = { minRarity = 4, threshold = 10 }
	local count = 0
	local got: string? = nil
	for _ = 1, 10 do
		local e
		e, count = WeightedRandom.rollWithPity(entries, always0, 1, pity, count)
		got = e.id
	end
	eq(got, "L", "10th roll should be legendary")
	eq(count, 0, "pity resets")
end)

print("RateLimiter")
test("token bucket blocks bursts and refills", function()
	local now = 0
	local rl = RateLimiter.new(2, 3, function()
		return now
	end)
	assert(rl:allow("p") and rl:allow("p") and rl:allow("p"), "burst of 3 allowed")
	assert(not rl:allow("p"), "4th blocked")
	now = 0.5
	assert(rl:allow("p"), "refilled 1 token after 0.5s")
	assert(not rl:allow("p"), "empty again")
end)

print("DataTemplate")
test("migrate fills missing nested keys without overwriting", function()
	local old: any = { coins = 50, stats = { rolls = 7 } }
	local d = DataTemplate.migrate(old)
	eq(d.coins, 50)
	eq(d.stats.rolls, 7)
	eq(d.stats.playSeconds, 0)
	eq(d.version, DataTemplate.VERSION)
	assert(type(d.purchaseHistory) == "table", "purchaseHistory added")
end)
test("trimPurchaseHistory bounds size", function()
	local d = DataTemplate.new()
	for i = 1, 300 do
		d.purchaseHistory[string.format("p%04d", i)] = true
	end
	DataTemplate.trimPurchaseHistory(d, 200)
	local n = 0
	for _ in d.purchaseHistory do
		n += 1
	end
	eq(n, 200)
	assert(d.purchaseHistory["p0300"], "newest kept")
end)

print("Delivery")
local square = { 50, 0, 0, 40, 0, 40, 40, 0, 40 } -- 高さ 50、40x40
local uShape = { 50, 0, 0, 90, 0, 90, 90, 80, 90, 80, 10, 10, 10, 10, 90, 0, 90 } -- コの字（重心が外）
test("roofs keeps solid footprints and drops U-shapes, low and tall ones", function()
	local filter = { minArea = 600, minHeight = 20, maxHeight = 110 }
	local tall = { 300, 0, 0, 40, 0, 40, 40, 0, 40 }
	local tiny = { 50, 0, 0, 10, 0, 10, 10, 0, 10 }
	local list = Delivery.roofs({ square, uShape, tall, tiny }, filter)
	eq(#list, 1)
	eq(list[1].x, 20)
	eq(list[1].z, 20)
	eq(list[1].y, 50)
	eq(list[1].area, 1600)
end)
test("pointInPolygon", function()
	local xs, zs = { 0, 40, 40, 0 }, { 0, 0, 40, 40 }
	assert(Delivery.pointInPolygon(20, 20, xs, zs), "inside")
	assert(not Delivery.pointInPolygon(50, 20, xs, zs), "outside")
end)
local line: { Delivery.Roof } = {}
for i = 0, 9 do
	table.insert(line, { x = i * 100, y = 50, z = 0, area = 1000 })
end
test("nextTarget stays within the distance band and never returns the origin", function()
	local rng = seeded(7)
	for _ = 1, 200 do
		local t = Delivery.nextTarget(line, 1, 150, 420, rng)
		assert(t ~= nil and t ~= 1, "valid target")
		local d = Delivery.horizontalDistance(line[1], line[t :: number])
		assert(d >= 150 and d <= 420, `distance {d}`)
	end
end)
test("nextTarget falls back to the closest-to-band roof, nil when alone", function()
	local two: { Delivery.Roof } = { line[1], line[2] }
	eq(Delivery.nextTarget(two, 1, 150, 420, seeded(1)), 2)
	eq(Delivery.nextTarget({ line[1] }, 1, 150, 420, seeded(1)), nil)
	eq(Delivery.nextTarget(line, 99, 150, 420, seeded(1)), nil)
end)
test("nearest and center", function()
	eq(Delivery.nearest(line, 260, 5), 4)
	eq(Delivery.nearest({}, 0, 0), nil)
	local cx, cz = Delivery.center(line)
	eq(cx, 450)
	eq(cz, 0)
end)
test("parSeconds adds climb only when going up", function()
	local cfg = { runSpeed = 20, climbSpeed = 10, baseSeconds = 4 }
	eq(Delivery.parSeconds(200, 30, cfg), 17)
	eq(Delivery.parSeconds(200, -30, cfg), 14)
end)
test("isPlausible rejects teleports, NaN and non-positive times", function()
	assert(Delivery.isPlausible(5, 300, 100), "3s minimum, 5s ok")
	assert(not Delivery.isPlausible(1, 300, 100), "too fast")
	assert(not Delivery.isPlausible(0, 0, 100), "zero")
	assert(not Delivery.isPlausible(0 / 0, 300, 100), "NaN")
end)
test("streak grows under par and resets when late", function()
	eq(Delivery.nextStreak(3, 9.9, 10), 4)
	eq(Delivery.nextStreak(3, 10.1, 10), 0)
end)
test("reward scales with distance, streak (capped) and multiplier", function()
	local cfg = { base = 10, perStud = 0.1, streakBonus = 0.1, streakCap = 10 }
	eq(Delivery.reward(300, 0, 1, cfg), 40)
	eq(Delivery.reward(300, 5, 1, cfg), 60)
	eq(Delivery.reward(300, 50, 1, cfg), 80)
	eq(Delivery.reward(300, 0, 1.5, cfg), 60)
end)
test("formatTime", function()
	eq(Delivery.formatTime(12.34), "0:12.3")
	eq(Delivery.formatTime(75), "1:15.0")
	eq(Delivery.formatTime(59.96), "1:00.0")
	eq(Delivery.formatTime(-3), "0:00.0")
end)
test("real district gives enough roofs and every roof has a target in range", function()
	local list = Delivery.roofs(CityData.buildings, GameConfig.Roofs)
	assert(#list >= 50, `roofs {#list}`)
	local rng = seeded(3)
	local inBand = 0
	local minD, maxD = GameConfig.Delivery.minDistance, GameConfig.Delivery.maxDistance
	for i in list do
		local t = Delivery.nextTarget(list, i, minD, maxD, rng)
		assert(t ~= nil and t ~= i, "has target")
		local d = Delivery.horizontalDistance(list[i], list[t :: number])
		if d >= minD and d <= maxD then
			inBand += 1
		end
	end
	eq(inBand, #list, "all roofs have an in-band target")
	print(`      roofs: {#list}`)
end)
test("upgrade caps keep the fastest legit run plausible", function()
	local up = GameConfig.Upgrades.Speed
	local top = GameConfig.Movement.walkSpeed + up.maxLevel * up.effectPerLevel
	local limit = top * GameConfig.Delivery.plausibleSpeedMargin
	assert(Delivery.isPlausible(300 / top, 300, limit), "max-speed run accepted")
	assert(GameConfig.Delivery.par.runSpeed < GameConfig.Movement.walkSpeed, "par beatable at base speed")
end)

print(`\n{passed} passed, {failed} failed`)
if failed > 0 then
	error("tests failed")
end

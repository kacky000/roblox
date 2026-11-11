--!strict
-- Lune で純粋ロジックをテストする:  lune run tests/run.luau
-- （Roblox API に依存しない src/shared/Lib のみ対象。サービスは Studio / Open Cloud Luau Execution で検証）

local Economy = require("../src/shared/Lib/Economy")
local WeightedRandom = require("../src/shared/Lib/WeightedRandom")
local RateLimiter = require("../src/shared/Lib/RateLimiter")
local DataTemplate = require("../src/shared/Lib/DataTemplate")
local DayNight = require("../src/shared/Lib/DayNight")
local GameConfig = require("../src/shared/Config/GameConfig")
local DayNight = require("../src/shared/Lib/DayNight")
local GameConfig = require("../src/shared/Config/GameConfig")

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

print("DayNight")
local dn = { daySeconds = 180, nightSeconds = 90, nightLuck = 3 }
test("phase switches at the boundaries and repeats", function()
	local p, left = DayNight.phase(0, dn)
	eq(p, "day")
	eq(left, 180)
	eq((DayNight.phase(179.5, dn)), "day")
	p, left = DayNight.phase(180, dn)
	eq(p, "night")
	eq(left, 90)
	eq((DayNight.phase(269.9, dn)), "night")
	eq((DayNight.phase(270, dn)), "day")
	eq((DayNight.phase(270 * 1000 + 200, dn)), "night")
end)
test("luck is boosted only at night", function()
	eq(DayNight.luck(10, dn), 1)
	eq(DayNight.luck(200, dn), 3)
	eq(DayNight.clockTime(10, dn), 14)
	eq(DayNight.clockTime(200, dn), 0)
end)
test("format shows minutes and seconds", function()
	eq(DayNight.format(90), "1:30")
	eq(DayNight.format(0.2), "0:01")
	eq(DayNight.format(-5), "0:00")
end)
test("night makes rare yokai more likely and odds still sum to 100", function()
	local entries = GameConfig.Eggs.Lantern.entries
	local day = WeightedRandom.oddsTable(entries, 1)
	local night = WeightedRandom.oddsTable(entries, GameConfig.DayNight.nightLuck)
	assert(night.Ryu > day.Ryu and night.Kitsune > day.Kitsune, "rare odds rise at night")
	local sum = 0
	for _, v in night do
		sum += v
	end
	assert(math.abs(sum - 100) < 0.01, "sum " .. sum)
end)

print(`\n{passed} passed, {failed} failed`)
if failed > 0 then
	error("tests failed")
end

--!strict
-- 屋上配達の純粋ロジック（Roblox API に依存しない。Lune でテストする）
-- 区画データの建物から「降りられる屋上」を選び、次の配達先・目標タイム・報酬を決める

local Delivery = {}

export type Roof = { x: number, y: number, z: number, area: number }

export type RoofFilter = { minArea: number, minHeight: number, maxHeight: number }

export type ParConfig = { runSpeed: number, climbSpeed: number, baseSeconds: number }

export type RewardConfig = {
	base: number,
	perStud: number,
	streakBonus: number, -- 連続達成1回ごとの上乗せ（0.1 = +10%）
	streakCap: number,
}

-- 多角形の符号付き面積と重心。xs/zs は 1 始まり
local function centroid(xs: { number }, zs: { number }): (number, number, number)
	local a, cx, cz = 0, 0, 0
	local n = #xs
	for i = 1, n do
		local j = i % n + 1
		local cross = xs[i] * zs[j] - xs[j] * zs[i]
		a += cross
		cx += (xs[i] + xs[j]) * cross
		cz += (zs[i] + zs[j]) * cross
	end
	a /= 2
	if math.abs(a) < 1e-6 then
		return 0, 0, 0
	end
	return math.abs(a), cx / (6 * a), cz / (6 * a)
end

-- 点が多角形の内側にあるか（交差数判定）
function Delivery.pointInPolygon(px: number, pz: number, xs: { number }, zs: { number }): boolean
	local inside = false
	local n = #xs
	local j = n
	for i = 1, n do
		if (zs[i] > pz) ~= (zs[j] > pz) then
			local t = (pz - zs[i]) / (zs[j] - zs[i])
			if px < xs[i] + t * (xs[j] - xs[i]) then
				inside = not inside
			end
		end
		j = i
	end
	return inside
end

-- 区画データの buildings（{ 高さ, x1, z1, x2, z2, ... }）から、配達に使える屋上を取り出す。
-- 重心が外形の外に出る建物（コの字など）は、着地点が屋根に乗らないので除く
function Delivery.roofs(buildings: { { number } }, filter: RoofFilter): { Roof }
	local out: { Roof } = {}
	for _, row in buildings do
		local h = row[1]
		local xs, zs = {}, {}
		for i = 2, #row - 1, 2 do
			table.insert(xs, row[i])
			table.insert(zs, row[i + 1])
		end
		if #xs >= 3 and h >= filter.minHeight and h <= filter.maxHeight then
			local area, cx, cz = centroid(xs, zs)
			if area >= filter.minArea and Delivery.pointInPolygon(cx, cz, xs, zs) then
				table.insert(out, { x = cx, y = h, z = cz, area = area })
			end
		end
	end
	return out
end

function Delivery.horizontalDistance(a: Roof, b: Roof): number
	local dx, dz = b.x - a.x, b.z - a.z
	return math.sqrt(dx * dx + dz * dz)
end

-- (x, z) に一番近い屋上の番号。空なら nil
function Delivery.nearest(roofs: { Roof }, x: number, z: number): number?
	local best: number? = nil
	local bestD = math.huge
	for i, r in roofs do
		local d = (r.x - x) ^ 2 + (r.z - z) ^ 2
		if d < bestD then
			best, bestD = i, d
		end
	end
	return best
end

-- 屋上全体の中心
function Delivery.center(roofs: { Roof }): (number, number)
	if #roofs == 0 then
		return 0, 0
	end
	local sx, sz = 0, 0
	for _, r in roofs do
		sx += r.x
		sz += r.z
	end
	return sx / #roofs, sz / #roofs
end

-- 次の配達先を選ぶ。from から minDist〜maxDist の屋上から乱数で1つ。
-- 範囲内に無ければ、minDist に一番近い別の屋上を返す。屋上が1つしか無ければ nil
function Delivery.nextTarget(
	roofs: { Roof },
	from: number,
	minDist: number,
	maxDist: number,
	rand: () -> number
): number?
	local origin = roofs[from]
	if not origin then
		return nil
	end
	local candidates: { number } = {}
	local fallback: number? = nil
	local fallbackGap = math.huge
	for i, r in roofs do
		if i ~= from then
			local d = Delivery.horizontalDistance(origin, r)
			if d >= minDist and d <= maxDist then
				table.insert(candidates, i)
			else
				local gap = math.abs(d - minDist)
				if gap < fallbackGap then
					fallback, fallbackGap = i, gap
				end
			end
		end
	end
	if #candidates > 0 then
		local k = math.clamp(math.floor(rand() * #candidates) + 1, 1, #candidates)
		return candidates[k]
	end
	return fallback
end

-- 目標タイム（これより速ければ連続達成が伸びる）
function Delivery.parSeconds(dist: number, climb: number, cfg: ParConfig): number
	return cfg.baseSeconds + dist / cfg.runSpeed + math.max(0, climb) / cfg.climbSpeed
end

-- 物理的にあり得る時間か（瞬間移動の検出）。maxSpeed は強化を全部積んだ速さ × 余裕
function Delivery.isPlausible(elapsed: number, dist: number, maxSpeed: number): boolean
	if elapsed ~= elapsed or elapsed <= 0 or maxSpeed <= 0 then
		return false
	end
	return elapsed >= dist / maxSpeed
end

-- 配達が終わったあとの連続達成数。目標タイム以内なら +1、遅れたら 0
function Delivery.nextStreak(streak: number, elapsed: number, par: number): number
	if elapsed <= par then
		return streak + 1
	end
	return 0
end

-- 報酬。streak は今回の配達を含めた連続達成数（遅れたら 0）
function Delivery.reward(dist: number, streak: number, multiplier: number, cfg: RewardConfig): number
	local bonus = 1 + math.min(math.max(streak, 0), cfg.streakCap) * cfg.streakBonus
	return math.floor((cfg.base + dist * cfg.perStud) * bonus * multiplier)
end

-- 12.34 -> "0:12.3"、75.0 -> "1:15.0"
function Delivery.formatTime(seconds: number): string
	local t = math.max(0, seconds)
	local tenths = math.floor(t * 10 + 0.5)
	local m = tenths // 600
	local s = (tenths % 600) / 10
	return string.format("%d:%04.1f", m, s)
end

return Delivery

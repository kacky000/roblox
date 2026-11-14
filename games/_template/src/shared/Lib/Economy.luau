--!strict
-- 経済式（純粋関数のみ。Roblox APIに依存しないので Lune でテスト可能）
-- インクリメンタル/シミュ系で定番の「指数コスト・リバース倍率・オフライン収益・数値の短縮表記」

local Economy = {}

-- n 個目のアップグレード価格: base * growth^n
-- growth 1.07〜1.15 が定番（Cookie Clicker 系 1.15、放置系 1.07）
function Economy.upgradeCost(base: number, growth: number, owned: number): number
	return math.floor(base * growth ^ owned)
end

-- k 個まとめ買いの合計価格（等比級数）
function Economy.bulkCost(base: number, growth: number, owned: number, k: number): number
	if k <= 0 then
		return 0
	end
	if growth == 1 then
		return math.floor(base * k)
	end
	return math.floor(base * growth ^ owned * (growth ^ k - 1) / (growth - 1))
end

-- 所持金で買える最大数
function Economy.maxAffordable(base: number, growth: number, owned: number, money: number): number
	if growth == 1 then
		return math.floor(money / base)
	end
	local n = math.floor(math.log(money * (growth - 1) / (base * growth ^ owned) + 1) / math.log(growth))
	return math.max(0, n)
end

-- リバース倍率: 1 + perRebirth * rebirths（線形）。後半は加速させたいなら exponent を >1 に
function Economy.rebirthMultiplier(rebirths: number, perRebirth: number, exponent: number?): number
	return 1 + perRebirth * rebirths ^ (exponent or 1)
end

-- リバースに必要な通貨（指数）
function Economy.rebirthCost(base: number, growth: number, rebirths: number): number
	return math.floor(base * growth ^ rebirths)
end

-- オフライン収益: 上限時間でキャップし、効率を掛ける（例: 50%、パス所持で100%）
function Economy.offlineEarnings(
	perSecond: number,
	secondsAway: number,
	capSeconds: number,
	efficiency: number
): number
	local t = math.clamp(secondsAway, 0, capSeconds)
	return math.floor(perSecond * t * efficiency)
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

-- 1234 -> "1.23K", 1.5e9 -> "1.5B"
function Economy.abbreviate(n: number): string
	if n ~= n then
		return "NaN"
	end
	local sign = if n < 0 then "-" else ""
	n = math.abs(n)
	if n < 1000 then
		return sign .. tostring(math.floor(n))
	end
	local tier = math.min(math.floor(math.log10(n) / 3), #SUFFIXES - 1)
	local scaled = n / 10 ^ (tier * 3)
	local s = string.format("%.2f", scaled):gsub("%.?0+$", "")
	return sign .. s .. SUFFIXES[tier + 1]
end

return Economy

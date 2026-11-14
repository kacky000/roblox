--!strict
-- 重み付き抽選（卵/ガチャ/ドロップ）＋ 運(luck)倍率 ＋ 天井(pity)
-- 抽選は必ずサーバーで実行すること（クライアント抽選は改ざんされる）
-- Roblox ポリシー: 有料ランダムアイテムは購入前に確率(オッズ)を表示する義務がある → oddsTable() を UI で使う

export type Entry = {
	id: string,
	weight: number,
	rarity: number?, -- 大きいほどレア。luck はこの値に応じてレア枠の重みを増やす
}

export type PityRule = {
	minRarity: number, -- この rarity 以上が出たらカウンタをリセット
	threshold: number, -- この回数ハズレが続いたら次回は minRarity 以上を確定
}

local WeightedRandom = {}

local function adjustedWeights(entries: { Entry }, luck: number): ({ number }, number)
	local weights = table.create(#entries)
	local total = 0
	for i, e in entries do
		local w = e.weight
		local r = e.rarity or 0
		if luck ~= 1 and r > 0 then
			-- レア度に応じて luck を効かせる（rarity=0 のコモンは不変）
			-- rarity 1 → luck^0.5, 2 → luck^1, 4以上 → luck^2（2x Luck パスで最上位が4倍）
			w *= luck ^ (math.min(r, 4) / 2)
		end
		weights[i] = w
		total += w
	end
	return weights, total
end

-- rng: 0 <= x < 1 を返す関数（サーバーでは Random.new():NextNumber をラップして渡す）
function WeightedRandom.roll(entries: { Entry }, rng: () -> number, luck: number?): Entry
	assert(#entries > 0, "entries must not be empty")
	local weights, total = adjustedWeights(entries, luck or 1)
	local x = rng() * total
	for i, w in weights do
		x -= w
		if x < 0 then
			return entries[i]
		end
	end
	return entries[#entries]
end

-- 天井付き抽選。pityCount は呼び出し側（プレイヤーデータ）で永続化する
function WeightedRandom.rollWithPity(
	entries: { Entry },
	rng: () -> number,
	luck: number?,
	pity: PityRule,
	pityCount: number
): (Entry, number)
	if pityCount + 1 >= pity.threshold then
		local pool = {}
		for _, e in entries do
			if (e.rarity or 0) >= pity.minRarity then
				table.insert(pool, e)
			end
		end
		if #pool > 0 then
			return WeightedRandom.roll(pool, rng, luck), 0
		end
	end
	local result = WeightedRandom.roll(entries, rng, luck)
	if (result.rarity or 0) >= pity.minRarity then
		return result, 0
	end
	return result, pityCount + 1
end

-- 表示用の確率表（%）。有料ガチャでは購入前に必ず見せる
function WeightedRandom.oddsTable(entries: { Entry }, luck: number?): { [string]: number }
	local weights, total = adjustedWeights(entries, luck or 1)
	local out = {}
	for i, e in entries do
		out[e.id] = weights[i] / total * 100
	end
	return out
end

return WeightedRandom

--!strict
-- 都市エンジン B 方式：osm_city.py が出力した city_data.luau から、実行時に Part で街を組み立てる。
-- アセットのアップロードが要らないので、区画データ（1 区画 数十 KB）を持っておけば何百都市でも組み立てられる。
--
-- 使い方（Roblox サーバー）:
--   local stats = CityBuilder.build(require(path.to.city_data), workspace.City)
-- 使い方（Lune。tools/city/bench_builder.luau）:
--   CityBuilder.build(data, model, { deps = roblox })   -- @lune/roblox を依存として渡す
--
-- 建物の作り方
--   - 外形がほぼ長方形（面積比 >= rectRatio）なら Part 1 個（壁と屋根をまとめて表現）
--   - それ以外は、辺ごとの壁 Part と、耳切り法で三角形分割した屋根（三角形 1 つ = WedgePart 2 個）

local CityBuilder = {}

export type Options = {
	deps: any?, -- Instance / Vector3 / CFrame / Color3 / Enum を持つテーブル（既定は Roblox のグローバル）
	rectRatio: number?, -- 長方形とみなす面積比（既定 0.85）
	minRoadWidth: number?, -- これより細い道路は作らない（studs。既定 0 = 全部）
	wallThickness: number?,
	yieldEvery: number?, -- Roblox 上でこの個数ごとに task.wait()（サーバーの固まり防止）。Lune では nil
}

export type Stats = {
	blocks: number,
	walls: number,
	wedges: number,
	roads: number,
	areas: number,
	total: number,
}

local WALL_COLORS = {
	{ 196, 196, 204 },
	{ 176, 182, 196 },
	{ 214, 206, 190 },
	{ 160, 166, 178 },
	{ 222, 214, 200 },
	{ 190, 176, 160 },
}

local function cross2(ox: number, oz: number, ax: number, az: number, bx: number, bz: number): number
	return (ax - ox) * (bz - oz) - (az - oz) * (bx - ox)
end

-- 反時計回り（cross > 0）の単純多角形を三角形分割する。xs/zs は 1 始まりの座標列
local function earClip(xs: { number }, zs: { number }): { { number } }
	local n = #xs
	local idx = table.create(n)
	for i = 1, n do
		idx[i] = i
	end
	local tris = {}
	local guard = 0
	while #idx > 3 and guard < n * n do
		guard += 1
		local found = false
		local m = #idx
		for k = 1, m do
			local i0, i1, i2 = idx[(k - 2) % m + 1], idx[k], idx[k % m + 1]
			if cross2(xs[i0], zs[i0], xs[i1], zs[i1], xs[i2], zs[i2]) > 1e-9 then
				local inside = false
				for _, j in idx do
					if j ~= i0 and j ~= i1 and j ~= i2 then
						local px, pz = xs[j], zs[j]
						if
							cross2(xs[i0], zs[i0], xs[i1], zs[i1], px, pz) >= 0
							and cross2(xs[i1], zs[i1], xs[i2], zs[i2], px, pz) >= 0
							and cross2(xs[i2], zs[i2], xs[i0], zs[i0], px, pz) >= 0
						then
							inside = true
							break
						end
					end
				end
				if not inside then
					table.insert(tris, { i0, i1, i2 })
					table.remove(idx, k)
					found = true
					break
				end
			end
		end
		if not found then
			break -- 自己交差など。残りは扇形で埋める
		end
	end
	for k = 2, #idx - 1 do
		table.insert(tris, { idx[1], idx[k], idx[k + 1] })
	end
	return tris
end

-- 最小面積の外接長方形（辺の向きを候補にする）。戻り値：中心 x, z、幅、奥行き、角度、面積
local function minRect(xs: { number }, zs: { number }): (number, number, number, number, number, number)
	local n = #xs
	local best = math.huge
	local bcx, bcz, bw, bd, bang = 0, 0, 0, 0, 0
	for i = 1, n do
		local j = i % n + 1
		local dx, dz = xs[j] - xs[i], zs[j] - zs[i]
		local len = math.sqrt(dx * dx + dz * dz)
		if len > 1e-6 then
			local ux, uz = dx / len, dz / len
			local minU, maxU, minV, maxV = math.huge, -math.huge, math.huge, -math.huge
			for p = 1, n do
				local u = xs[p] * ux + zs[p] * uz
				local v = -xs[p] * uz + zs[p] * ux
				minU, maxU = math.min(minU, u), math.max(maxU, u)
				minV, maxV = math.min(minV, v), math.max(maxV, v)
			end
			local area = (maxU - minU) * (maxV - minV)
			if area < best then
				best = area
				local cu, cv = (minU + maxU) / 2, (minV + maxV) / 2
				bcx, bcz = cu * ux - cv * uz, cu * uz + cv * ux
				bw, bd = maxU - minU, maxV - minV
				bang = math.atan2(uz, ux)
			end
		end
	end
	return bcx, bcz, bw, bd, bang, best
end

local function polyArea(xs: { number }, zs: { number }): number
	local a = 0
	local n = #xs
	for i = 1, n do
		local j = i % n + 1
		a += xs[i] * zs[j] - xs[j] * zs[i]
	end
	return a / 2
end

function CityBuilder.build(data: any, parent: Instance, opts: Options?): Stats
	local o: Options = opts or {}
	local R = o.deps
		or { Instance = Instance, Vector3 = Vector3, CFrame = CFrame, Color3 = Color3, Enum = Enum }
	local V3, CF, C3 = R.Vector3, R.CFrame, R.Color3
	local rectRatio = o.rectRatio or 0.85
	local thick = o.wallThickness or 1
	local stats: Stats = { blocks = 0, walls = 0, wedges = 0, roads = 0, areas = 0, total = 0 }

	local function part(className: string, size: any, cframe: any, color: { number }, material: any): any
		local p = R.Instance.new(className)
		p.Anchored = true
		p.CanQuery = true
		p.CastShadow = className ~= "WedgePart"
		p.Size = size
		p.CFrame = cframe
		p.Color = C3.fromRGB(color[1], color[2], color[3])
		p.Material = material
		p.TopSurface = R.Enum.SurfaceType.Smooth
		p.BottomSurface = R.Enum.SurfaceType.Smooth
		p.Parent = parent
		stats.total += 1
		if o.yieldEvery and stats.total % o.yieldEvery == 0 then
			task.wait()
		end
		return p
	end

	-- 3 点 a, b, c を WedgePart 2 個で埋める（よく知られた分解法）
	local function triangle(a: any, b: any, c: any, t: number, color: { number }, material: any)
		local ab, ac, bc = b - a, c - a, c - b
		local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
		if abd > acd and abd > bcd then
			c, a = a, c
		elseif acd > bcd and acd > abd then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		if ac:Cross(ab).Magnitude < 1e-6 or bc.Magnitude < 1e-6 then
			return
		end
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local height = math.abs(ab:Dot(up))
		local w1, w2 = math.abs(ab:Dot(back)), math.abs(ac:Dot(back))
		if height < 0.05 then
			return
		end
		if w1 > 0.05 then
			part(
				"WedgePart",
				V3.new(t, height, w1),
				CF.fromMatrix((a + b) / 2, right, up, back),
				color,
				material
			)
			stats.wedges += 1
		end
		if w2 > 0.05 then
			part(
				"WedgePart",
				V3.new(t, height, w2),
				CF.fromMatrix((a + c) / 2, -right, up, -back),
				color,
				material
			)
			stats.wedges += 1
		end
	end

	local function segment(
		x1: number,
		z1: number,
		x2: number,
		z2: number,
		width: number,
		y: number,
		h: number,
		color,
		material
	)
		local dx, dz = x2 - x1, z2 - z1
		local len = math.sqrt(dx * dx + dz * dz)
		if len < 0.05 then
			return
		end
		local mid = V3.new((x1 + x2) / 2, y, (z1 + z2) / 2)
		part("Part", V3.new(width, h, len), CF.lookAt(mid, mid + V3.new(dx, 0, dz)), color, material)
	end

	local concrete, plastic = R.Enum.Material.Concrete, R.Enum.Material.SmoothPlastic

	for bi, row in data.buildings do
		local h = row[1]
		local xs, zs = {}, {}
		for i = 2, #row - 1, 2 do
			table.insert(xs, row[i])
			table.insert(zs, row[i + 1])
		end
		if #xs >= 3 then
			local color = WALL_COLORS[(bi % #WALL_COLORS) + 1]
			local area = math.abs(polyArea(xs, zs))
			local cx, cz, w, d, ang, rectArea = minRect(xs, zs)
			if rectArea > 0 and area / rectArea >= rectRatio then
				part("Part", V3.new(w, h, d), CF.new(cx, h / 2, cz) * CF.Angles(0, -ang, 0), color, concrete)
				stats.blocks += 1
			else
				for i = 1, #xs do
					local j = i % #xs + 1
					segment(xs[i], zs[i], xs[j], zs[j], thick, h / 2, h, color, concrete)
					stats.walls += 1
				end
				local roofColor = { color[1] - 50, color[2] - 50, color[3] - 50 }
				for _, t in earClip(xs, zs) do
					local i0, i1, i2 = t[1], t[2], t[3]
					triangle(
						V3.new(xs[i0], h, zs[i0]),
						V3.new(xs[i1], h, zs[i1]),
						V3.new(xs[i2], h, zs[i2]),
						0.4,
						roofColor,
						plastic
					)
				end
			end
		end
	end

	local minRoad = o.minRoadWidth or 0
	local function strips(list: { { number } }, color, material, y: number)
		for _, row in list do
			local width = row[1]
			if width >= minRoad then
				for i = 2, #row - 3, 2 do
					segment(row[i], row[i + 1], row[i + 2], row[i + 3], width, y, 0.2, color, material)
					stats.roads += 1
				end
			end
		end
	end
	strips(data.roads, { 70, 72, 78 }, R.Enum.Material.Asphalt, 0.1)
	strips(data.rails, { 96, 72, 56 }, R.Enum.Material.Slate, 0.2)

	for _, row in data.areas do
		local color = if row[1] == 1 then { 90, 160, 210 } else { 110, 170, 100 }
		local xs, zs = {}, {}
		for i = 2, #row - 1, 2 do
			table.insert(xs, row[i])
			table.insert(zs, row[i + 1])
		end
		if #xs >= 3 then
			for _, t in earClip(xs, zs) do
				local i0, i1, i2 = t[1], t[2], t[3]
				triangle(
					V3.new(xs[i0], 0.05, zs[i0]),
					V3.new(xs[i1], 0.05, zs[i1]),
					V3.new(xs[i2], 0.05, zs[i2]),
					0.1,
					color,
					plastic
				)
				stats.areas += 1
			end
		end
	end

	return stats
end

return CityBuilder

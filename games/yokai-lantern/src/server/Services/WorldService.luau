--!strict
-- 最低限のワールド（地面とスポーン地点）を用意する。
-- Rojo のビルドは Workspace が空なので、これが無いとプレイヤーは空中に出て落ち続ける（2026-11-15 に Studio で確認）。
-- ゲームごとの見た目は decorate() に足す。すでに SpawnLocation があれば何もしない

local WorldService = {}

local GROUND_SIZE = 512

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end
WorldService.part = part

-- 神社の飾り：鳥居、参道、提灯（夜に光る）。すべて Part で作る仮の見た目
function WorldService.decorate(world: Folder)
	local red = Color3.fromRGB(200, 50, 40)
	local wood = Enum.Material.Wood
	-- 参道
	part({
		Name = "Path",
		Size = Vector3.new(14, 0.4, 120),
		Position = Vector3.new(0, 0.2, -66),
		Material = Enum.Material.Cobblestone,
		Color = Color3.fromRGB(170, 170, 175),
	}, world)
	-- 鳥居（参道に 3 基）
	for i = 1, 3 do
		local z = -30 * i
		local torii = Instance.new("Model")
		torii.Name = "Torii" .. i
		for _, x in { -8, 8 } do
			part({
				Name = "Pillar",
				Size = Vector3.new(2, 20, 2),
				Position = Vector3.new(x, 10, z),
				Material = wood,
				Color = red,
			}, torii)
		end
		part({
			Name = "Beam",
			Size = Vector3.new(22, 1.6, 2),
			Position = Vector3.new(0, 16, z),
			Material = wood,
			Color = red,
		}, torii)
		part({
			Name = "Top",
			Size = Vector3.new(28, 2, 3),
			Position = Vector3.new(0, 20.6, z),
			Material = wood,
			Color = Color3.fromRGB(40, 40, 45),
		}, torii)
		torii.Parent = world
	end
	-- 提灯（参道の両脇）
	for i = 0, 7 do
		for _, x in { -11, 11 } do
			local z = -12 - i * 14
			part({
				Name = "Post",
				Size = Vector3.new(0.8, 7, 0.8),
				Position = Vector3.new(x, 3.5, z),
				Material = wood,
				Color = Color3.fromRGB(70, 50, 40),
			}, world)
			local lantern = part({
				Name = "Lantern",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(3, 3, 3),
				Position = Vector3.new(x, 8, z),
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 170, 80),
			}, world)
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 180, 100)
			light.Range = 24
			light.Brightness = 2
			light.Parent = lantern
		end
	end
	-- 拝殿（奥の建物）
	part({
		Name = "ShrineFloor",
		Size = Vector3.new(44, 3, 30),
		Position = Vector3.new(0, 1.5, -150),
		Material = wood,
		Color = Color3.fromRGB(120, 85, 60),
	}, world)
	part({
		Name = "ShrineWall",
		Size = Vector3.new(36, 14, 20),
		Position = Vector3.new(0, 10, -154),
		Material = wood,
		Color = Color3.fromRGB(235, 225, 205),
	}, world)
	part({
		Name = "ShrineRoof",
		Size = Vector3.new(50, 3, 34),
		Position = Vector3.new(0, 18.5, -152),
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(45, 55, 70),
	}, world)
end

function WorldService.start()
	if workspace:FindFirstChildWhichIsA("SpawnLocation", true) then
		return
	end
	local world = Instance.new("Folder")
	world.Name = "World"

	part({
		Name = "Ground",
		Size = Vector3.new(GROUND_SIZE, 4, GROUND_SIZE),
		Position = Vector3.new(0, -2, 0),
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(96, 150, 84),
	}, world)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Material = Enum.Material.Slate
	spawn.Color = Color3.fromRGB(150, 150, 160)
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Neutral = true
	spawn.Parent = world

	WorldService.decorate(world)
	world.Parent = workspace
end

return WorldService

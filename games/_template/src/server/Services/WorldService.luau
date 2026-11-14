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

-- ゲームごとの飾り。テンプレートでは何も置かない
function WorldService.decorate(_world: Folder) end

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

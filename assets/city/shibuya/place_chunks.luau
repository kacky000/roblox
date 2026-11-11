--!strict
-- shibuya: OBJ を Workspace にインポートした後、コマンドバーに貼って実行する（自動生成）
-- © OpenStreetMap contributors (ODbL 1.0) — ゲーム内とストアページにクレジットを表示すること
local POS: { [string]: Vector3 } = {
	["chunk_-3_-2_0"] = Vector3.new(-2543.741, 0.150, -1805.893),
	["chunk_-3_1_0"] = Vector3.new(-2465.876, 0.250, 1128.497),
	["chunk_-2_-2_0"] = Vector3.new(-1738.896, 66.607, -1776.992),
	["chunk_-2_-1_0"] = Vector3.new(-1583.228, 62.857, -868.654),
	["chunk_-2_0_0"] = Vector3.new(-1783.758, 88.036, 285.868),
	["chunk_-2_1_0"] = Vector3.new(-1794.364, 81.250, 1251.515),
	["chunk_-2_2_0"] = Vector3.new(-1884.975, 0.150, 2039.843),
	["chunk_-1_-2_0"] = Vector3.new(-798.665, 68.393, -1737.733),
	["chunk_-1_-1_0"] = Vector3.new(-980.339, 81.964, -681.804),
	["chunk_-1_0_0"] = Vector3.new(-744.587, 62.679, 297.207),
	["chunk_-1_1_0"] = Vector3.new(-767.488, 185.643, 1272.873),
	["chunk_0_-3_0"] = Vector3.new(145.184, 0.250, -2549.750),
	["chunk_0_-2_0"] = Vector3.new(301.288, 80.714, -1708.202),
	["chunk_0_-1_0"] = Vector3.new(128.757, 84.821, -822.260),
	["chunk_0_0_0"] = Vector3.new(164.349, 410.189, 516.610),
	["chunk_0_1_0"] = Vector3.new(314.689, 321.375, 1517.636),
	["chunk_0_2_0"] = Vector3.new(360.781, 0.200, 2024.916),
	["chunk_1_-2_0"] = Vector3.new(1246.725, 102.857, -1870.840),
	["chunk_1_-1_0"] = Vector3.new(990.221, 111.339, -763.120),
	["chunk_1_0_0"] = Vector3.new(1312.839, 325.893, 254.449),
	["chunk_1_1_0"] = Vector3.new(821.193, 321.339, 1208.926),
	["chunk_1_2_0"] = Vector3.new(1225.874, 0.200, 2015.662),
	["chunk_2_-1_0"] = Vector3.new(2003.574, 0.150, -954.673),
}
local folder = workspace:FindFirstChild("City_shibuya") or Instance.new("Folder")
folder.Name = "City_shibuya"
folder.Parent = workspace
local placed = 0
for _, inst in workspace:GetDescendants() do
	local pos = POS[inst.Name]
	if pos and inst:IsA("MeshPart") then
		inst.Anchored = true
		inst.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
		inst.Position = pos
		inst.Parent = folder
		placed += 1
	end
end
print(("placed %d / %d chunks"):format(placed, 23))

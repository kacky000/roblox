--!strict
-- CityBuilder（B 方式）を Lune で実行し、Part 数・生成時間・モデルの大きさを測る。Studio は不要。
-- 使い方: lune run tools/city/bench_builder.luau assets/city/shibuya/city_data.luau [out.rbxm]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local CityBuilder = require("./CityBuilder")

local dataPath = process.args[1]
assert(dataPath, "usage: lune run tools/city/bench_builder.luau <city_data.luau> [out.rbxm]")
local data = luau.load(fs.readFile(dataPath), { debugName = dataPath })()

local model = roblox.Instance.new("Model")
model.Name = "City_" .. data.name
local t0 = os.clock()
local minRoadWidth = tonumber(process.env.MIN_ROAD_WIDTH or "0") or 0 -- 例: MIN_ROAD_WIDTH=15 で歩道を省く
local stats = CityBuilder.build(data, model, { deps = roblox, minRoadWidth = minRoadWidth })
local dt = os.clock() - t0

local bytes = roblox.serializeModel({ model })
print(
	("%s: buildings=%d → parts=%d (blocks=%d walls=%d wedges=%d roads=%d areas=%d)"):format(
		data.name,
		#data.buildings,
		stats.total,
		stats.blocks,
		stats.walls,
		stats.wedges,
		stats.roads,
		stats.areas
	)
)
print(
	("build %.2fs (Lune, PC), rbxm %.1f KB, data %.1f KB"):format(
		dt,
		#bytes / 1024,
		#fs.readFile(dataPath) / 1024
	)
)
if process.args[2] then
	fs.writeFile(process.args[2], bytes)
	print("wrote " .. process.args[2])
end

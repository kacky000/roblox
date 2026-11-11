--!strict
-- サーバーのエントリポイント。サービスを依存順に起動する
local Services = script.Services

local order = { "DataService", "MonetizationService", "GameService" }
for _, name in order do
	local mod = require(Services:FindFirstChild(name) :: ModuleScript) :: any
	local t0 = os.clock()
	mod.start()
	print(`[Server] {name} started ({math.floor((os.clock() - t0) * 1000)}ms)`)
end

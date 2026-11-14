-- Open Cloud の Luau Execution で実行する起動テスト（tools/factory/factory.py smoke が送る）。
-- この環境では place 内のスクリプトは自動で動かないので、サーバーのサービスを起動順に手で start する。
-- プレイヤーはいないので、確認できるのは「起動時にエラーが出ないこと」と「歩ける世界があること」まで
local server = game:GetService("ServerScriptService"):FindFirstChild("Server")
if not server or not server:FindFirstChild("Services") then
	return { ok = false, error = "ServerScriptService.Server.Services がない" }
end

local order = { "WorldService", "DataService", "MonetizationService", "GameService" }
local results = {}
local ok = true
for _, name in order do
	local m = server.Services:FindFirstChild(name)
	if m then
		local good, err = pcall(function()
			(require(m) :: any).start()
		end)
		table.insert(results, { name = name, ok = good, error = if good then nil else tostring(err) })
		ok = ok and good
	else
		table.insert(results, { name = name, ok = true, error = "（なし）" })
	end
end
task.wait(3) -- 起動直後のループで出るエラーを拾う

local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
local parts = 0
for _, d in workspace:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
	end
end
local hasGround = false
if spawn then
	local hit = workspace:Raycast(spawn.Position + Vector3.new(0, 50, 0), Vector3.new(0, -500, 0))
	hasGround = hit ~= nil
end

return {
	ok = ok and spawn ~= nil and hasGround,
	services = results,
	hasSpawn = spawn ~= nil,
	hasGround = hasGround,
	parts = parts,
	remotes = #game:GetService("ReplicatedStorage"):GetDescendants(),
}

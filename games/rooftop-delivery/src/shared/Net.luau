--!strict
-- リモート定義を一箇所に集約。サーバーが生成し、クライアントは待つ
-- 鉄則: クライアントから来た値は全部ウソかもしれない前提で、サーバー側で型・範囲・回数を検証する

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	"RequestUpgrade", -- client -> server (upgradeId: string)
	"DataChanged", -- server -> client (patch: table)
	"Notify", -- server -> client (message: string)
	"JobChanged", -- server -> client ({ x, y, z, par, streak, distance })
	"JobDone", -- server -> client ({ elapsed, par, coins, streak })
}

local Net = {}

local folder: Folder
if RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in EVENTS do
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function Net.event(name: string): RemoteEvent
	local re = folder:WaitForChild(name, 10)
	assert(re and re:IsA("RemoteEvent"), `Unknown remote: {name}`)
	return re
end

-- サーバー用: 引数の型チェック付きでハンドラを接続
function Net.onServer(name: string, argTypes: { string }, handler: (Player, ...any) -> ())
	Net.event(name).OnServerEvent:Connect(function(player: Player, ...)
		local args = table.pack(...)
		if args.n ~= #argTypes then
			return
		end
		for i, t in argTypes do
			if typeof(args[i]) ~= t then
				return
			end
			if t == "string" and #args[i] > 64 then
				return
			end
			if t == "number" and (args[i] ~= args[i] or math.abs(args[i]) == math.huge) then
				return -- NaN / inf 対策
			end
		end
		handler(player, table.unpack(args, 1, args.n))
	end)
end

return Net

--!strict
-- クライアントのエントリポイント
for _, mod in script.Controllers:GetChildren() do
	if mod:IsA("ModuleScript") then
		local c = require(mod) :: any
		c.start()
	end
end

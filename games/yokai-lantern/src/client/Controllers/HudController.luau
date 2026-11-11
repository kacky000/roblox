--!strict
-- 最小HUD（コード生成UI）。本番UIは Figma→画像アセット or UIライブラリ(React-lua/Fusion/Vide) に置き換える
-- モバイル比率が高いので: ボタンは大きく(>=44px相当)、画面下部に配置、Scaleベースで配置

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Economy = require(Shared.Lib.Economy)
local GameConfig = require(Shared.Config.GameConfig)
local Net = require(Shared.Net)
local WeightedRandom = require(Shared.Lib.WeightedRandom)
local DayNight = require(Shared.Lib.DayNight)

local HudController = {}

local function make(className: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function button(parent: Instance, text: string, pos: UDim2, color: Color3, onClick: () -> ())
	local b = make("TextButton", {
		Size = UDim2.fromScale(0.2, 0.09),
		Position = pos,
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = color,
		Text = text,
		TextScaled = true,
		Font = Enum.Font.FredokaOne,
		TextColor3 = Color3.new(1, 1, 1),
	}, parent)
	make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, b)
	make(
		"UIStroke",
		{ Thickness = 3, Color = Color3.fromRGB(30, 30, 50), ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
		b
	)
	make("UIAspectRatioConstraint", { AspectRatio = 2.6 }, b)
	b.Activated:Connect(function()
		local s = b.Size
		TweenService
			:Create(b, TweenInfo.new(0.06), { Size = UDim2.fromScale(s.X.Scale * 0.92, s.Y.Scale * 0.92) })
			:Play()
		task.delay(0.06, function()
			TweenService:Create(b, TweenInfo.new(0.1, Enum.EasingStyle.Back), { Size = s }):Play()
		end)
		onClick()
	end)
	return b
end

function HudController.start()
	local gui = make(
		"ScreenGui",
		{ Name = "HUD", ResetOnSpawn = false, IgnoreGuiInset = false },
		Players.LocalPlayer:WaitForChild("PlayerGui")
	)

	local coinLabel = make("TextLabel", {
		Size = UDim2.fromScale(0.3, 0.08),
		Position = UDim2.fromScale(0.5, 0.02),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = "🪙 0",
		TextScaled = true,
		Font = Enum.Font.FredokaOne,
		TextColor3 = Color3.fromRGB(255, 220, 80),
	}, gui)
	make("UIStroke", { Thickness = 3 }, coinLabel)

	local toast = make("TextLabel", {
		Size = UDim2.fromScale(0.5, 0.06),
		Position = UDim2.fromScale(0.5, 0.16),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		TextTransparency = 1,
		TextScaled = true,
		Font = Enum.Font.FredokaOne,
		TextColor3 = Color3.new(1, 1, 1),
	}, gui)

	-- 確率表示（購入前のオッズ表示が規約上必須）。夜は運が上がるので、時間帯が変わるたびに運込みの確率に更新する
	local egg = GameConfig.Eggs.Lantern
	local oddsLabel = make("TextLabel", {
		Size = UDim2.fromScale(0.18, 0.18),
		Position = UDim2.fromScale(0.25, 0.86),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 0.4,
		BackgroundColor3 = Color3.fromRGB(20, 20, 40),
		Text = "",
		TextScaled = true,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
	}, gui)
	local phaseLabel = make("TextLabel", {
		Size = UDim2.fromScale(0.3, 0.05),
		Position = UDim2.fromScale(0.5, 0.1),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextScaled = true,
		Font = Enum.Font.FredokaOne,
		TextColor3 = Color3.new(1, 1, 1),
	}, gui)
	make("UIStroke", { Thickness = 2 }, phaseLabel)
	local shownPhase: string? = nil
	task.spawn(function()
		while gui.Parent do
			local now = workspace:GetServerTimeNow()
			local phase, left = DayNight.phase(now, GameConfig.DayNight)
			phaseLabel.Text = if phase == "night"
				then `🌙 夜 あと {DayNight.format(left)}`
				else `☀ 昼 夜まで {DayNight.format(left)}`
			if phase ~= shownPhase then
				shownPhase = phase
				local odds = WeightedRandom.oddsTable(egg.entries, DayNight.luck(now, GameConfig.DayNight))
				local lines = {}
				for _, e in egg.entries do
					table.insert(lines, string.format("%s %.1f%%", e.id, odds[e.id]))
				end
				oddsLabel.Text = table.concat(lines, "\n")
			end
			task.wait(1)
		end
	end)

	button(gui, "提灯で誘う (100)", UDim2.fromScale(0.25, 0.97), Color3.fromRGB(90, 160, 255), function()
		Net.event("RequestRoll"):FireServer("Lantern")
	end)
	button(gui, "収入UP", UDim2.fromScale(0.5, 0.97), Color3.fromRGB(80, 200, 120), function()
		Net.event("RequestUpgrade"):FireServer("Income")
	end)
	local rebirthBtn = button(
		gui,
		"リバース",
		UDim2.fromScale(0.75, 0.97),
		Color3.fromRGB(230, 90, 160),
		function()
			Net.event("RequestRebirth"):FireServer()
		end
	)

	Net.event("DataChanged").OnClientEvent:Connect(function(d)
		coinLabel.Text = "🪙 " .. Economy.abbreviate(d.coins)
		local cost = Economy.rebirthCost(GameConfig.Rebirth.base, GameConfig.Rebirth.growth, d.rebirths)
		rebirthBtn.Text = `リバース ({Economy.abbreviate(cost)})`
	end)

	Net.event("Notify").OnClientEvent:Connect(function(msg: string)
		toast.Text = msg
		toast.TextTransparency = 0
		TweenService:Create(toast, TweenInfo.new(2.5), { TextTransparency = 1 }):Play()
	end)
end

return HudController

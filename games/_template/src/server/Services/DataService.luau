--!strict
-- プレイヤーデータの読み書き（DataStore）
-- 対策済み: リトライ / セッションロック（二重ログインでの巻き戻り・複製防止）/ 自動保存 / BindToClose / スキーマ移行
-- 大規模化したら ProfileStore（loleris）への置き換えを推奨。インターフェースは get/update のまま差し替えられる

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local DataTemplate = require(Shared.Lib.DataTemplate)

type PlayerData = DataTemplate.PlayerData

local DataService = {}

local store = DataStoreService:GetDataStore(GameConfig.DataStoreName)
local JOB_ID = if RunService:IsStudio() then "studio-" .. HttpService:GenerateGUID(false) else game.JobId
local LOCK_EXPIRE = 30 * 60 -- 30分更新が無いロックは失効扱い（サーバークラッシュ対策）

local cache: { [Player]: PlayerData } = {}
local dirty: { [Player]: boolean } = {}
local loadedSignal = Instance.new("BindableEvent")

local function keyFor(userId: number): string
	return "u_" .. userId
end

local function withRetry<T>(fn: () -> T, tries: number): (boolean, T?)
	for i = 1, tries do
		local ok, res = pcall(fn)
		if ok then
			return true, res
		end
		warn(`[DataService] attempt {i} failed: {res}`)
		task.wait(math.min(2 ^ i, 10))
	end
	return false, nil
end

local function load(player: Player): PlayerData?
	local key = keyFor(player.UserId)
	local result = nil :: PlayerData?
	local lockedElsewhere = false
	local ok = withRetry(function()
		store:UpdateAsync(key, function(old: any): any
			local now = os.time()
			if old and old.__lock and old.__lock.job ~= JOB_ID and now - old.__lock.t < LOCK_EXPIRE then
				lockedElsewhere = true
				return nil -- 書き込まない
			end
			local data = if old then DataTemplate.migrate(old) else DataTemplate.new()
			;(data :: any).__lock = { job = JOB_ID, t = now }
			result = data
			return data
		end)
		return true
	end, 5)
	if lockedElsewhere then
		-- 別サーバーがまだ保存中。少し待って再試行するのが定石
		task.wait(5)
		if player.Parent then
			return load(player)
		end
		return nil
	end
	if not ok then
		return nil
	end
	return result
end

local function save(player: Player, release: boolean)
	local data = cache[player]
	if not data then
		return
	end
	DataTemplate.trimPurchaseHistory(data, 200)
	data.lastOnline = os.time()
	local key = keyFor(player.UserId)
	withRetry(function()
		store:UpdateAsync(key, function(old: any): any
			if old and old.__lock and old.__lock.job ~= JOB_ID then
				return nil -- 他サーバーにロックを奪われている → 上書きしない
			end
			local out = table.clone(data) :: any
			out.__lock = if release then nil else { job = JOB_ID, t = os.time() }
			return out
		end)
		return true
	end, 3)
	dirty[player] = nil
end

function DataService.get(player: Player): PlayerData?
	return cache[player]
end

-- データ変更は必ずこれを通す（dirty フラグ管理）
function DataService.update(player: Player, fn: (PlayerData) -> ())
	local data = cache[player]
	if data then
		fn(data)
		dirty[player] = true
	end
end

-- 読み込み完了まで待つ
function DataService.waitFor(player: Player): PlayerData?
	while player.Parent and cache[player] == nil do
		loadedSignal.Event:Wait()
	end
	return cache[player]
end

DataService.Loaded = loadedSignal.Event -- (player, data)

function DataService.saveNow(player: Player)
	save(player, false)
end

function DataService.start()
	local function onJoin(player: Player)
		local data = load(player)
		if not player.Parent then
			return
		end
		if not data then
			player:Kick("データの読み込みに失敗しました。再参加してください。 / Failed to load data, please rejoin.")
			return
		end
		cache[player] = data
		loadedSignal:Fire(player, data)
	end
	Players.PlayerAdded:Connect(onJoin)
	for _, p in Players:GetPlayers() do
		task.spawn(onJoin, p)
	end

	Players.PlayerRemoving:Connect(function(player)
		save(player, true)
		cache[player] = nil
		dirty[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(GameConfig.AutosaveSeconds)
			for player in dirty do
				task.spawn(save, player, false)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in cache do
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
		local t0 = os.clock()
		while pending > 0 and os.clock() - t0 < 25 do
			task.wait(0.1)
		end
	end)
end

return DataService

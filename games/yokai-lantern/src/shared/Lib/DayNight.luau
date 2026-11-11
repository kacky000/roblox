--!strict
-- 昼夜サイクルの純粋ロジック。サーバー時刻（全サーバー共通）から決まるので、どのサーバーでも同じ時刻に夜が来る
-- 昼は神社を育てる時間、夜は妖怪を誘いやすい時間（luck が上がる）

local DayNight = {}

export type Config = {
	daySeconds: number,
	nightSeconds: number,
	nightLuck: number, -- 夜の luck 倍率（昼は 1）
}

export type Phase = "day" | "night"

-- 戻り値：今の時間帯、その時間帯の残り秒数
function DayNight.phase(now: number, cfg: Config): (Phase, number)
	local cycle = cfg.daySeconds + cfg.nightSeconds
	local t = now % cycle
	if t < cfg.daySeconds then
		return "day", cfg.daySeconds - t
	end
	return "night", cycle - t
end

function DayNight.luck(now: number, cfg: Config): number
	local p = DayNight.phase(now, cfg)
	return if p == "night" then cfg.nightLuck else 1
end

-- Lighting.ClockTime 用（昼は 14 時、夜は 0 時）
function DayNight.clockTime(now: number, cfg: Config): number
	local p = DayNight.phase(now, cfg)
	return if p == "night" then 0 else 14
end

function DayNight.format(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

return DayNight

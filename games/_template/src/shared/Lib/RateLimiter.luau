--!strict
-- トークンバケット方式のレート制限（RemoteEvent 連打・エクスプロイト対策）
-- 例: local limiter = RateLimiter.new(5, 10) -- 1秒に5回回復、最大10回まで溜まる
--     if not limiter:allow(player.UserId) then return end

export type RateLimiter = {
	rate: number,
	burst: number,
	clock: () -> number,
	buckets: { [any]: { tokens: number, last: number } },
	allow: (self: RateLimiter, key: any, cost: number?) -> boolean,
	forget: (self: RateLimiter, key: any) -> (),
}

local RateLimiter = {}

local function allow(self: RateLimiter, key: any, cost: number?): boolean
	local c = cost or 1
	local now = self.clock()
	local b = self.buckets[key]
	if not b then
		b = { tokens = self.burst, last = now }
		self.buckets[key] = b
	end
	b.tokens = math.min(self.burst, b.tokens + (now - b.last) * self.rate)
	b.last = now
	if b.tokens >= c then
		b.tokens -= c
		return true
	end
	return false
end

local function forget(self: RateLimiter, key: any)
	self.buckets[key] = nil
end

function RateLimiter.new(ratePerSecond: number, burst: number, clock: (() -> number)?): RateLimiter
	return {
		rate = ratePerSecond,
		burst = burst,
		clock = clock or os.clock,
		buckets = {},
		allow = allow,
		forget = forget,
	}
end

return RateLimiter

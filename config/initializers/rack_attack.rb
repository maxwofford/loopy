class Rack::Attack
  # API rate limit: 1 req/sec per token (shared with SMTP via RateLimiter)
  blocklist("rate_limit/api") do |req|
    if req.path.start_with?("/api/v1/")
      auth_header = req.get_header("HTTP_AUTHORIZATION")
      if auth_header&.start_with?("Bearer ")
        token = auth_header.sub("Bearer ", "")
        begin
          RateLimiter.check!(token)
          false
        rescue RateLimiter::LimitExceeded
          true
        end
      end
    end
  end

  blocklisted_responder = lambda do |req|
    [
      429,
      { "Content-Type" => "application/json" },
      [{ error: "Rate limit exceeded. Max #{RateLimiter::MAX_REQUESTS} request per second." }.to_json]
    ]
  end

  # General site rate limit: 60 req/min per IP
  throttle("req/ip", limit: 60, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/api/v1/")
  end
end

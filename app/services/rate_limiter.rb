class RateLimiter
  class LimitExceeded < StandardError; end

  PERIOD = 1.second
  MAX_REQUESTS = 1

  @@requests = Hash.new { |h, k| h[k] = [] }
  @@mutex = Mutex.new

  def self.reset!
    @@mutex.synchronize { @@requests.clear }
  end

  def self.check!(key)
    return if key.blank?

    @@mutex.synchronize do
      now = Time.current
      cutoff = now - PERIOD

      @@requests[key].reject! { |t| t < cutoff }

      if @@requests[key].size >= MAX_REQUESTS
        raise LimitExceeded, "Rate limit exceeded. Max #{MAX_REQUESTS} request per second."
      end

      @@requests[key] << now
    end
  end
end

require "vcr"
require "webmock/minitest"

VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = false

  config.filter_sensitive_data("<LOOPS_API_KEY>") { ENV.fetch("LOOPS_API_KEY", "test-key") }

  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
end

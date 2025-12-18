require "midi-smtp-server"

class LoopySmtpServer < MidiSmtpServer::Smtpd
  def initialize(port: 2525, host: "127.0.0.1", tls_cert: nil, tls_key: nil)
    tls_opts = if tls_cert && tls_key && File.exist?(tls_cert) && File.exist?(tls_key)
      {
        tls_mode: :TLS_OPTIONAL,
        tls_cert_path: tls_cert,
        tls_key_path: tls_key
      }
    else
      { tls_mode: :TLS_FORBIDDEN }
    end

    super(
      ports: port.to_s,
      hosts: host,
      max_processings: 4,
      auth_mode: :AUTH_REQUIRED,
      logger_severity: Logger::INFO,
      **tls_opts
    )
  end

  def on_auth_event(ctx, authorization_id, authentication_id, authentication)
    @current_team_id = authentication_id
    @current_raw_key = authentication
    @current_api_key = authenticate_loopy_key(authentication)

    if @current_api_key.nil?
      raise MidiSmtpServer::Smtpd535Exception, "535 Authentication failed: Invalid API key"
    end

    if @current_api_key.revoked?
      raise MidiSmtpServer::Smtpd535Exception, "535 Authentication failed: API key has been revoked"
    end

    unless @current_api_key.has_scope?("transactional:send")
      raise MidiSmtpServer::Smtpd535Exception, "535 Authentication failed: API key missing required scope"
    end

    @current_api_key
  end

  def on_message_data_event(ctx)
    check_rate_limit!(@current_raw_key)

    envelope_from = ctx[:envelope][:from]
    envelope_to = ctx[:envelope][:to]
    message_data = ctx[:message][:data]

    body = extract_body(message_data)
    payload = parse_payload(body)

    response = forward_to_loops(payload)

    log_request(payload, response)

    if response.status >= 400
      raise MidiSmtpServer::Smtpd550Exception, "550 Delivery failed: #{response.body}"
    end
  end

  private

  def authenticate_loopy_key(raw_key)
    ApiKey.find_by_raw_key(raw_key)
  end

  def extract_body(message_data)
    parts = message_data.split(/\r?\n\r?\n/, 2)
    parts[1]&.strip || ""
  end

  def parse_payload(body)
    JSON.parse(body)
  rescue JSON::ParserError
    { "raw_body" => body }
  end

  def forward_to_loops(payload)
    conn = Faraday.new(url: "https://app.loops.so")
    conn.post("/api/v1/transactional") do |req|
      req.headers["Authorization"] = "Bearer #{ENV.fetch('LOOPS_API_KEY')}"
      req.headers["Content-Type"] = "application/json"
      req.body = payload.to_json
    end
  end

  def log_request(payload, response)
    return unless @current_api_key

    ApiRequest.create!(
      api_key: @current_api_key,
      endpoint: "/smtp",
      request_body: @current_api_key.log_request_body? ? payload.except("attachments") : {},
      response_status: response.status,
      ip_address: "127.0.0.1",
      fingerprint: { source: "smtp", team_id: @current_team_id }
    )
  end

  def check_rate_limit!(raw_key)
    RateLimiter.check!(raw_key)
  rescue RateLimiter::LimitExceeded => e
    raise MidiSmtpServer::Smtpd450Exception, "450 #{e.message}"
  end
end

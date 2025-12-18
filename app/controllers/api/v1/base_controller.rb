class Api::V1::BaseController < ActionController::API
  before_action :authenticate_api_key!

  private

  def authenticate_api_key!
    auth_header = request.headers["Authorization"]
    unless auth_header&.start_with?("Bearer ")
      return render json: { error: "Missing authorization header" }, status: :unauthorized
    end

    raw_key = auth_header.sub("Bearer ", "")
    @api_key = ApiKey.find_by_raw_key(raw_key)

    if @api_key.nil?
      render json: { error: "Invalid API key" }, status: :unauthorized
    elsif @api_key.revoked?
      render json: { error: "API key has been revoked" }, status: :unauthorized
    end
  end

  def require_scope!(scope)
    unless @api_key.has_scope?(scope)
      render json: { error: "API key does not have required scope: #{scope}" }, status: :forbidden
    end
  end

  def client_ip
    request.headers["CF-Connecting-IP"] ||
      request.headers["X-Forwarded-For"]&.split(",")&.first&.strip ||
      request.remote_ip
  end

  def request_fingerprint
    {
      ip: client_ip,
      user_agent: request.user_agent,
      cf_country: request.headers["CF-IPCountry"]
    }.compact
  end

end

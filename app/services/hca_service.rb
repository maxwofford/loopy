module HCAService
  def host
    # TODO: use https://hca.dinosaurbbq.org in development
    "https://auth.hackclub.com"
  end

  def authorization_url(state:, redirect_uri:)
    params = {
      response_type: "code",
      client_id: ENV.fetch("HCA_CLIENT_ID"),
      redirect_uri: redirect_uri,
      scope: "openid profile email",
      state: state
    }
    "#{host}/oauth/authorize?#{params.to_query}"
  end

  def fetch_tokens(code:, redirect_uri:)
    conn = Faraday.new(url: host)
    response = conn.post("/oauth/token") do |req|
      req.body = {
        grant_type: "authorization_code",
        code: code,
        redirect_uri: redirect_uri,
        client_id: ENV.fetch("HCA_CLIENT_ID"),
        client_secret: ENV.fetch("HCA_CLIENT_SECRET")
      }
    end
    raise "Token request failed: #{response.body}" unless response.success?
    JSON.parse(response.body)
  end

  def userinfo(access_token)
    raise ArgumentError, "access_token is required" unless access_token

    conn = Faraday.new(url: host)
    response = conn.get("/oauth/userinfo") do |req|
      req.headers["Authorization"] = "Bearer #{access_token}"
    end
    raise "Userinfo request failed: #{response.body}" unless response.success?
    JSON.parse(response.body)
  end

  module_function :host, :authorization_url, :fetch_tokens, :userinfo
end

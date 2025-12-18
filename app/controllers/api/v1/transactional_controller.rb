class Api::V1::TransactionalController < Api::V1::BaseController
  before_action -> { require_scope!("transactional:send") }

  def create
    api_request = ApiRequest.create!(
      api_key: @api_key,
      endpoint: "/api/v1/transactional",
      request_body: @api_key.log_request_body? ? filtered_request_body : {},
      response_status: 102, # Processing - will be updated after Loops responds
      ip_address: client_ip,
      fingerprint: request_fingerprint
    )

    loops_response = proxy_to_loops
    api_request.update!(response_status: loops_response.status)

    render json: JSON.parse(loops_response.body), status: loops_response.status
  end

  private

  def proxy_to_loops
    conn = Faraday.new(url: "https://app.loops.so")
    conn.post("/api/v1/transactional") do |req|
      req.headers["Authorization"] = "Bearer #{ENV.fetch('LOOPS_API_KEY')}"
      req.headers["Content-Type"] = "application/json"
      req.body = request.raw_post
    end
  end

  def filtered_request_body
    body = JSON.parse(request.raw_post) rescue {}
    body.except("attachments")
  end
end

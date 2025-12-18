require "test_helper"

class Api::V1::TransactionalControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_key = api_keys(:active_key)
    @raw_key = "auth!userone@test-project_20251216.testsecret123"
    RateLimiter.reset!
  end

  test "proxies request to loops.so and returns success" do
    VCR.use_cassette("loops_transactional_success") do
      post api_v1_transactional_path,
        params: {
          transactionalId: "cmiw99wj70qkx330ixxs0olyr",
          email: "test@example.com",
          dataVariables: { test_key: "123" }
        },
        headers: { "Authorization" => "Bearer #{@raw_key}" },
        as: :json

      assert_response :success
      assert_equal({ "success" => true }, response.parsed_body)
    end
  end

  test "logs the request in api_requests" do
    VCR.use_cassette("loops_transactional_success") do
      assert_difference "ApiRequest.count", 1 do
        post api_v1_transactional_path,
          params: {
            transactionalId: "cmiw99wj70qkx330ixxs0olyr",
            email: "test@example.com",
            dataVariables: { test_key: "123" }
          },
          headers: { "Authorization" => "Bearer #{@raw_key}" },
          as: :json
      end

      api_request = ApiRequest.last
      assert_equal @api_key.id, api_request.api_key_id
      assert_equal "/api/v1/transactional", api_request.endpoint
      assert_equal 200, api_request.response_status
    end
  end

  test "returns error for invalid api key" do
    post api_v1_transactional_path,
      params: { transactionalId: "test", email: "test@example.com" },
      headers: { "Authorization" => "Bearer invalid-key" },
      as: :json

    assert_response :unauthorized
    assert_equal({ "error" => "Invalid API key" }, response.parsed_body)
  end

  test "returns error for revoked api key" do
    raw_key = "auth!usertwo@revoked-project_20251216.revokedsecret"

    post api_v1_transactional_path,
      params: { transactionalId: "test", email: "test@example.com" },
      headers: { "Authorization" => "Bearer #{raw_key}" },
      as: :json

    assert_response :unauthorized
    assert_equal({ "error" => "API key has been revoked" }, response.parsed_body)
  end

  test "returns error for api key without required scope" do
    raw_key = "auth!userone@no-scope-project_20251216.noscopesecret"

    post api_v1_transactional_path,
      params: { transactionalId: "test", email: "test@example.com" },
      headers: { "Authorization" => "Bearer #{raw_key}" },
      as: :json

    assert_response :forbidden
    assert_equal({ "error" => "API key does not have required scope: transactional:send" }, response.parsed_body)
  end

  test "proxies loops.so error responses" do
    VCR.use_cassette("loops_transactional_missing_data_variables") do
      post api_v1_transactional_path,
        params: {
          transactionalId: "cmiw99wj70qkx330ixxs0olyr",
          email: "test@example.com"
        },
        headers: { "Authorization" => "Bearer #{@raw_key}" },
        as: :json

      assert_response :bad_request
      assert_equal false, response.parsed_body["success"]
      assert_includes response.parsed_body["message"], "dataVariables"
    end
  end
end

require "test_helper"
require "net/smtp"

class SmtpRelayTest < ActiveSupport::TestCase
  setup do
    @api_key = api_keys(:active_key)
    @raw_key = "auth!userone@test-project_20251216.testsecret123"
    @team_id = ENV.fetch("LOOPS_TEAM_ID", "test-team-id")
    @smtp_port = 2525 + rand(1000)
    RateLimiter.reset!
  end

  teardown do
    stop_smtp_server
  end

  test "accepts email with valid loopy credentials and forwards to loops.so" do
    VCR.use_cassette("smtp_relay_success") do
      start_smtp_server

      smtp = Net::SMTP.new("127.0.0.1", @smtp_port)
      smtp.start("localhost", @team_id, @raw_key, :plain) do |session|
        payload = {
          transactionalId: "cmiw99wj70qkx330ixxs0olyr",
          email: "test@example.com",
          dataVariables: { test_key: "123" }
        }.to_json

        message = <<~EMAIL
          From: sender@example.com
          To: test@example.com
          Subject: Test Email

          #{payload}
        EMAIL

        session.send_message(message, "sender@example.com", "test@example.com")
      end

      assert_equal 1, ApiRequest.where(api_key: @api_key, endpoint: "/smtp").count
    end
  end

  test "rejects email with invalid loopy credentials" do
    start_smtp_server

    smtp = Net::SMTP.new("127.0.0.1", @smtp_port)

    assert_raises(Net::SMTPAuthenticationError) do
      smtp.start("localhost", @team_id, "invalid-key", :plain) do |session|
        session.send_message("test", "from@example.com", "to@example.com")
      end
    end
  end

  test "rejects email with revoked loopy credentials" do
    start_smtp_server

    revoked_key = "auth!usertwo@revoked-project_20251216.revokedsecret"
    smtp = Net::SMTP.new("127.0.0.1", @smtp_port)

    assert_raises(Net::SMTPAuthenticationError) do
      smtp.start("localhost", @team_id, revoked_key, :plain) do |session|
        session.send_message("test", "from@example.com", "to@example.com")
      end
    end
  end

  test "rejects email with loopy key missing transactional:send scope" do
    start_smtp_server

    no_scope_key = "auth!userone@no-scope-project_20251216.noscopesecret"
    smtp = Net::SMTP.new("127.0.0.1", @smtp_port)

    assert_raises(Net::SMTPAuthenticationError) do
      smtp.start("localhost", @team_id, no_scope_key, :plain) do |session|
        session.send_message("test", "from@example.com", "to@example.com")
      end
    end
  end

  private

  def start_smtp_server
    @smtp_server = LoopySmtpServer.new(port: @smtp_port)
    @smtp_thread = Thread.new { @smtp_server.start }
    sleep 0.2
  end

  def stop_smtp_server
    @smtp_server&.stop
    @smtp_thread&.join(1)
  rescue StandardError
    nil
  end
end

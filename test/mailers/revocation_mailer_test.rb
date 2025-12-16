require "test_helper"

class RevocationMailerTest < ActionMailer::TestCase
  test "key_revoked" do
    api_key = api_keys(:revoked_key)
    mail = RevocationMailer.key_revoked(api_key)

    assert_equal "[Loopy] Your API key for 'revoked-project' has been revoked", mail.subject
    assert_equal [api_key.user.email], mail.to
    assert_equal ["loopy@hackclub.com"], mail.from
    assert_match "revoked-project", mail.body.encoded
    assert_match "API Key Revoked", mail.body.encoded
  end
end

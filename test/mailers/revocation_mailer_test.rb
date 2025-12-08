require "test_helper"

class RevocationMailerTest < ActionMailer::TestCase
  test "key_revoked" do
    mail = RevocationMailer.key_revoked
    assert_equal "Key revoked", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end

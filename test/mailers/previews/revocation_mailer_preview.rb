# Preview all emails at http://localhost:3000/rails/mailers/revocation_mailer
class RevocationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/revocation_mailer/key_revoked
  def key_revoked
    RevocationMailer.key_revoked
  end
end

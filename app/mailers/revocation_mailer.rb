class RevocationMailer < ApplicationMailer
  def key_revoked(api_key)
    @api_key = api_key
    @user = api_key.user

    mail(
      to: @user.email,
      subject: "[Loopy] Your API key for '#{api_key.project}' has been revoked"
    )
  end
end

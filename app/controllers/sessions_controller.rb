class SessionsController < ApplicationController
  def new
    state = SecureRandom.hex(32)
    session[:oauth_state] = state

    redirect_to HCAService.authorization_url(state: state, redirect_uri: callback_session_url), allow_other_host: true
  end

  def callback
    if params[:state] != session.delete(:oauth_state)
      return redirect_to root_path, alert: "Invalid state parameter"
    end

    token_response = HCAService.fetch_tokens(code: params[:code], redirect_uri: callback_session_url)
    userinfo = HCAService.userinfo(token_response["access_token"])

    email = userinfo["email"] || "#{userinfo['sub']}@hca.local"
    user = User.find_or_create_by!(hca_id: userinfo["sub"]) do |u|
      u.email = email
    end
    user.update!(email: email) if user.email != email

    session[:user_id] = user.id
    redirect_to root_path, notice: "Signed in successfully"
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Signed out"
  end
end

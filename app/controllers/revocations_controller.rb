class RevocationsController < ApplicationController
  def new
    @key = params[:key]
  end

  def create
    raw_key = params[:key]
    api_key = ApiKey.find_by_raw_key(raw_key)

    if api_key.nil?
      flash[:alert] = "API key not found"
      return redirect_to new_revocation_path
    end

    if api_key.revoked?
      flash[:notice] = "This API key was already revoked"
      return redirect_to new_revocation_path
    end

    api_key.revoke!
    RevocationMailer.key_revoked(api_key).deliver_later

    flash[:notice] = "API key has been revoked. The owner has been notified."
    redirect_to new_revocation_path
  end
end

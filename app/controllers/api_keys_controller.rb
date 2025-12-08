class ApiKeysController < ApplicationController
  before_action :require_auth

  def index
    @api_keys = current_user.api_keys.order(created_at: :desc)
  end

  def show
    @api_key = current_user.api_keys.find(params[:id])
    @api_requests = @api_key.api_requests.order(created_at: :desc).page(params[:page])
  end

  def new
    @api_key = ApiKey.new
  end

  def create
    @api_key = ApiKey.generate(
      user: current_user,
      project: params[:api_key][:project],
      scopes: Array(params[:api_key][:scopes]).reject(&:blank?)
    )
    flash[:notice] = "API key created: #{@api_key.raw_key}. Copy this because you won't see it again!"
    redirect_to api_keys_path
  end

  def destroy
    api_key = current_user.api_keys.find(params[:id])
    api_key.revoke!
    flash[:notice] = "API key revoked for '#{api_key.project}'"
    redirect_to api_keys_path
  end
end

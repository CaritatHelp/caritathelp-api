class LogoutController < ApplicationController
  swagger_controller :logout, "Logout management"

  skip_before_filter :verify_authenticity_token
  before_filter :check_token

  swagger_api :index do
    summary "Allow volunteer to logout"
    param :query, :token, :string, :required, "Your token"
    response :ok
  end
  def index
    user = Volunteer.find_by token: params[:token]
    user.token = nil
    user.save
    render :json => create_response(nil, 200, t("logout.success"))
  end
end

class LogoutController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :check_token

  api :POST, '/logout', "Allow volunteer to logout"
  param :token, String, "Your token", :required => true
  example SampleJson.logout('index')
  def index
    user = Volunteer.find_by token: params[:token]
    user.token = nil
    user.save
    render :json => create_response(nil, 200, t("logout.success"))
  end
end

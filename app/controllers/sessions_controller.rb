class SessionsController < DeviseTokenAuth::SessionsController

  swagger_controller :sessions, "Sessions manager"

  
  swagger_api :create do
    summary "sign_in volunteer"
    param :form, :email, :string, :required, "Your email"
    param :form, :password, :string, :required, "Your password"
    response :ok
  end
  def create
    super
  end

  swagger_api :destroy do
    summary "sign_out volunteer"
    param :form, 'access-token', :string, :required, "Your token"
    param :form, 'client', :string, :required, "Your client token"
    param :form, 'uid', :string, :required, "Your uid"
    response :ok
  end
  def destroy
    super
  end
end

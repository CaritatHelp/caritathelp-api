class PasswordsController < DeviseTokenAuth::PasswordsController

  swagger_controller :passwords, "Passwords manager"

  swagger_api :update do
    summary "change volunteer's password"
    param :header, 'access-token', :string, :required, "Your token"
    param :header, 'client', :string, :required, "Your client token"
    param :header, 'uid', :string, :required, "Your uid"
    param :form, :password, :string, :required, "New password"
    param :form, :password_confirmation, :string, :required, "New password confirmation"
    response :ok
  end
  def update
    super
  end
end

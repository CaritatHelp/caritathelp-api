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

  protected
  def render_update_error_unauthorized
    render json: {
             status: 401,
             message: "Unauthorized",
             response: nil
           }, status: 401
  end

  def render_update_error_password_not_required
    render json: {
             status: 422,
             message: "Password not required",
             response: nil
           }, status: 422
  end

  def render_update_error_missing_password
    render json: {
             status: 422,
             message: "Missing password",
             response: nil
           }, status: 422
  end

  def render_update_success
    render json: {
             status: 200,
             message: "ok",
             response: resource_data,
           }, status: 200
  end

  def render_update_error
    return render json: {
                    status: 422,
                    message: resource_errors[:full_messages].to_sentence,
                    response: nil
                  }, status: 422
  end
end

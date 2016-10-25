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
    param :header, 'access-token', :string, :required, "Your token"
    param :header, 'client', :string, :required, "Your client token"
    param :header, 'uid', :string, :required, "Your uid"
    response :ok
  end
  def destroy
    super
  end

  protected
  def render_create_success
    render json: {
             status: 200,
             message: "ok",
             response: resource_data(resource_json: @resource.token_validation_response)
           }
  end

  def render_create_error_not_confirmed
    render json: {
             status: 401,
             message: "Volunteer not confirmed",
             response: nil
           }, status: 401
  end

  def render_create_error_bad_credentials
    render json: {
             status: 401,
             message: "Bad credentials",
             response: nil
           }, status: 401
  end

  def render_destroy_success
    render json: {
             status: 200,
             message: "ok",
             response: "Volunteer successfuly logged out"
           }, status: 200
  end

  def render_destroy_error
    render json: {
             status: 404,
             message: "Volunteer not found",
             response: nil
           }, status: 404
  end
end

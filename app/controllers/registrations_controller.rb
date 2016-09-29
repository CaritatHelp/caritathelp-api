class RegistrationsController < DeviseTokenAuth::RegistrationsController

  swagger_controller :registrations, "Registrations manager"

  swagger_api :create do
    summary "Allow a volunteer to create an account"
    param :query, :email, :string, :required, "Volunteer's email"
    param :query, :firstname, :string, :required, "Volunteer's firstname"
    param :query, :lastname, :string, :required, "Volunteer's lastname"
    param :query, :password, :string, :required, "Volunteer's password"
    param :query, :birthday, :date,  :optional, "Volunteer's birthday"
    param :query, :gender, :string,  :optional, "Volunteer's gender"
    param :query, :city, :string,  :optional, "Volunteer's city"    
    param :query, :latitude, :decimal,  :optional, "Volunteer's latitude position"    
    param :query, :longitude, :decimal,  :optional, "Volunteer's longitude position"    
    param :query, :allowgps, :boolean,  :optional, "Volunteer allows GPS localisation?"    
    param :query, :allow_notifications, :boolean,  :optional, "Volunteer allows notifications?"    
    response :ok
    response 400
  end
  def create
    super
  end

  swagger_api :update do
    summary "Allow a volunteer to update his account"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :email, :string, :optional, "Volunteer's email"
    param :query, :firstname, :string, :optional, "Volunteer's firstname"
    param :query, :lastname, :string, :optional, "Volunteer's lastname"
    param :query, :birthday, :date,  :optional, "Volunteer's birthday"
    param :query, :gender, :string,  :optional, "Volunteer's gender"
    param :query, :city, :string,  :optional, "Volunteer's city"    
    param :query, :latitude, :decimal,  :optional, "Volunteer's latitude position"    
    param :query, :longitude, :decimal,  :optional, "Volunteer's longitude position"    
    param :query, :allowgps, :boolean,  :optional, "Volunteer allows GPS localisation?"    
    param :query, :allow_notifications, :boolean,  :optional, "Volunteer allows notifications?"    
    response :ok
    response 400
  end
  def update
    if @resource
      if @resource.send(resource_update_method, account_update_params)
        yield @resource if block_given?
        render_update_success
      else
        render_update_error
      end
    else
      render_update_error_user_not_found
    end
  end
  
  def sign_up_params
    params.permit(:firstname, :lastname, :email, :password, :password_confirmation, :birthday,
                  :gender, :city, :latitude, :longitude, :allowgps, :allow_notifications)
  end

  def account_update_params
    params.permit(:firstname, :lastname, :email, :birthday, :gender, :city, :latitude, :longitude,
                  :allowgps, :allow_notifications)
  end

  protected
  def render_create_success
    render json: {
             status: 200,
             message: "ok",
             response: resource_data
           }
  end

  def render_create_error
    render json: {
             status: 400,
             message: resource_errors[:full_messages].to_sentence,
             response: nil
           }
  end

  def render_update_success
    render json: {
             status: 200,
             message: "ok",
             response: resource_data
           }
  end

  def render_update_error
    render json: {
             status: 400,
             message: resource_errors[:full_messages].to_sentence,
             response: nil
           }
  end

  def render_update_error_user_not_found
    render json: {
             status: 400,
             message: "User not found",
             response: nil
           }
  end
end

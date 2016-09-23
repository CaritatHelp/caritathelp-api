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
    super
  end
  
  def sign_up_params
    params.permit(:firstname, :lastname, :email, :password, :password_confirmation, :birthday,
                  :gender, :city, :latitude, :longitude, :allowgps, :allow_notifications)
  end

  def account_update_params
    params.permit(:firstname, :lastname, :email, :birthday, :gender, :city, :latitude, :longitude,
                  :allowgps, :allow_notifications)
  end
end

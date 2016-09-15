class RegistrationsController < DeviseTokenAuth::RegistrationsController

  # def_param_group :volunteers_creation do
  #   param :email, String, "Your email address", :required => true
  #   param :password, String, "Chosen password, must contain letters and numbers", :required => true
  #   param :firstname, String, "Your firstname", :required => true
  #   param :lastname, String, "Your lastname", :required => true
  #   param :birthday, Date, "Your birthday"
  #   param :gender, String, "Must be 'm' or 'f'"
  #   param :city, String, "Your current city"
  #   param :latitude, Float, "Latitude position"
  #   param :longitude, Float, "Longitude position"
  #   param :allowgps, String, "Must be 'true' or 'false' for allowing geolocalisation"
  #   param :allow_notifications, String, "Must be 'true' or 'false' for allowing notifications"
  # end

  # def_param_group :volunteers_update do
  #   param :token, String, "Your token", :required => true
  #   param :email, String, "Your email address"
  #   param :password, String, "Chosen password, must contain letters and numbers"
  #   param :firstname, String, "Your firstname"
  #   param :lastname, String, "Your lastname"
  #   param :birthday, Date, "Your birthday"
  #   param :gender, String, "Must be 'm' or 'f'"
  #   param :city, String, "Your current city"
  #   param :latitude, Float, "Latitude position"
  #   param :longitude, Float, "Longitude position"
  #   param :allowgps, String, "Must be 'true' or 'false' for allowing geolocalisation"
  #   param :allow_notifications, String, "Must be 'true' or 'false' for allowing notifications"
  # end


  # remettre les header pour create et update pour la doc?
  def sign_up_params
    params.permit(:firstname, :lastname, :email, :password, :password_confirmation)
  end
end

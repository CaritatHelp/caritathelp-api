class LoginController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def_param_group :login do
    param :email, String, "Your email address", :required => true
    param :password, String, "Your password", :required => true
  end

  api :POST, '/login', "Allow a volunteer to log into the app"
  param_group :login
  example SampleJson.login('index')
  def index
    if (missing_param = param_is_missing?) != nil
      render :json => create_error(400, t("login.failure.params."+missing_param.to_s+".missing"))
      return
    end

    if !Volunteer.exist?(user_params[:email])
      render :json => create_error(400, t("login.failure.params.email.wrong"))
      return
    end

    db_user = Volunteer.find_by email: user_params[:email]
    new_user = Volunteer.new(user_params)

    if db_user.password.eql? new_user.password
      db_user.generate_token
      db_user.save
      render :json => create_response(db_user.as_json(:except => [:password]))
      return
    end

    render :json => create_error(400, t("login.failure.params.password.wrong"))
  end

  private
  def user_params
    params.permit(:email, :password)
  end

  def param_is_missing?
    hash = user_params
    [:email, :password].each do |key|
      if !hash.has_key? key
        return key.to_s
      end
    end
    return nil
  end
end

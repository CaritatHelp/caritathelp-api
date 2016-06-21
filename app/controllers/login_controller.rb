class LoginController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def_param_group :login do
    param :mail, String, "Your mail address", :required => true
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

    if !Volunteer.exist?(user_params[:mail])
      render :json => create_error(400, t("login.failure.params.mail.wrong"))
      return
    end

    db_user = Volunteer.find_by mail: user_params[:mail]
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
    params.permit(:mail, :password)
  end

  def param_is_missing?
    hash = user_params
    [:mail, :password].each do |key|
      if !hash.has_key? key
        return key.to_s
      end
    end
    return nil
  end
end

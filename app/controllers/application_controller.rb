class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_action :set_locale
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  def cors_preflight_check
    if request.method == 'OPTIONS'
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Token'
      headers['Access-Control-Max-Age'] = '1728000'
      
      render :text => '', :content_type => 'text/plain'
    end
  end

  def set_locale
    I18n.available_locales = [:en, :fr]
    I18n.locale = params[:locale] || :en
  end

  def check_token
    if params[:token] == nil or !Volunteer.find_by(token: params[:token])
      render :json => create_error(400, t("token.wrong"))
      return
    end
  end

  def create_response(result, status = 200, message = 'ok')
    {:status => status, :message => message, :response => result}
  end

  def create_error(status, message)
    {:status => status, :message => message, :response => nil}
  end

  def send_notif_to_socket(notification_id)
    begin
      WebSocket::Client::Simple.connect("ws://" + Rails.application.config.ip + ":" + Rails.application.config.port_websocket) do |ws|
        ws.on :open do
          ws.send("#{ENV['NOTIF_CARITATHELP']} #{notification_id}")
          ws.close
        end
      end
    rescue
    end
  end
end

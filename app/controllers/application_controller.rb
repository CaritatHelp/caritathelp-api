class ApplicationController < ActionController::Base
  include DeviseTokenAuth::Concerns::SetUserByToken
  include CanCan::ControllerAdditions
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_action :set_locale
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  def cors_preflight_check
    if request.method == 'OPTIONS'
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Content-Type, Token'
      headers['Access-Control-Max-Age'] = '1728000'

      render :text => '', :content_type => 'text/plain'
    end
  end

  def set_locale
    I18n.available_locales = [:en, :fr]
    I18n.locale = params[:locale] || :fr
  end

  def create_response(result, status = 200, message = 'ok')
    {:status => status, :message => message, :response => result}
  end

  def create_error(status, message)
    {:status => status, :message => message, :response => nil}
  end

  def send_notif_to_socket(notification)
    begin
      concerned_volunteers = Volunteer.joins(:notification_volunteers)
        .where(notification_volunteers: { notification_id: notification.id })
        .select("volunteers.id, volunteers.uid").all

      if concerned_volunteers.empty?
        concerned_volunteers = Volunteer.where(id: notification.receiver_id)
          .select("volunteers.id, volunteers.uid").all
      end

      json_msg = {
        token: ENV['NOTIF_CARITATHELP'],
        sender_id: notification.sender_id,
        receiver_id: notification.receiver_id,
        assoc_id: notification.assoc_id,
        event_id: notification.event_id,
        notif_type: notification.notif_type,
        assoc_name: notification.assoc_name,
        event_name: notification.event_name,
        sender_name: notification.sender_name,
        receiver_name: notification.receiver_name,
        sender_thumb_path: notification.sender_thumb_path,
        receiver_thumb_path: notification.receiver_thumb_path,
        concerned_volunteers: concerned_volunteers
      }.to_json

      WebSocket::Client::Simple.connect("ws://" + Rails.application.config.ip + ":" +
                                        Rails.application.config.port_websocket.to_s) do |ws|
        ws.on :open do
          ws.send(json_msg)
          ws.close
        end
      end
    rescue => e
    end
  end

  def is_swagger_request?
    if request.headers['access-token'] == "superuser" and request.headers[:client] == "superuser"
      return true
    end
    return false
  end

  alias_method :devise_current_volunteer, :current_volunteer
  def current_volunteer
    if is_swagger_request?
      volunteer = Volunteer.find_by(email: request.headers[:uid])
      return volunteer unless volunteer.blank?
      Volunteer.first
    else
      super
    end
  end
end

class NotificationsController < ApplicationController
  swagger_controller :notifications, "Notifications management"

  before_action :authenticate_volunteer!, unless: :is_swagger_request?

  before_action :set_notification
  
  swagger_api :read do
    summary "Set a notification as read"
    param :path, :id, :integer, :required, "Notification's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end  
  def read
    # modify to handle authorization
    @notification.read = true
    @notification.save
    render :json => create_response(@notification)
  end

  swagger_api :reply_emergency do
    summary "Reply to emergency notification"
    param :path, :id, :integer, :required, "Notification's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :form, :accept, :boolean, :optional, "True to accept, false otherwise"
    response :ok
  end
  def reply_emergency
    notif = Notification.select { |notif|
      notif.receiver_id == current_volunteer.id and notif.is_emergency? and notif.id == params[:id].to_i
    }.first

    if notif.blank?
      render json: create_error(400, t("notifications.failure.id")) and return
    end

    if params[:accept]
      notif.notif_type = "AcceptedEmergency"
    else
      notif.notif_type = "RefusedEmergency"
    end

    if notif.save
      render json: create_response(t("notifications.success.reply_emergency"))
    else
      render json: create_error(400, t("notifications.failure.reply_emergency")) and return
    end
  end

  private
  
  def set_notification
    begin
      @notification = Notification.find(params[:id])
    rescue
      render :json => create_error(400, t("notifications.failure.id"))
    end
  end
end

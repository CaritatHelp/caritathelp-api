class NotificationsController < ApplicationController
  swagger_controller :notifications, "Notifications management"

  before_action :authenticate_volunteer!

  before_action :set_notification
  
  swagger_api :read do
    summary "Set a notification as read"
    param :path, :id, :integer, :required, "Notification's id"
    param :query, :token, :string, :required, "Your token"
    response :ok
  end  
  def read
    @notification.read = true
    @notification.save
    render :json => create_response(@notification)
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

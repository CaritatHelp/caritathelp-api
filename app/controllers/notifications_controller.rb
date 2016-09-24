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
  
  private
  
  def set_notification
    begin
      @notification = Notification.find(params[:id])
    rescue
      render :json => create_error(400, t("notifications.failure.id"))
    end
  end
end

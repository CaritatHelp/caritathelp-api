class NotificationsController < ApplicationController
  before_action :authenticate_volunteer!
  
  before_action :set_notification
  
  api :PUT, '/notifications/:id/read', "Set a notification as read"
  param :token, String, "Your token", :required => true
  example SampleJson.notifications('read')
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

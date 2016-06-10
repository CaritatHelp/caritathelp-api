class NotificationVolunteer < ActiveRecord::Base
  validates :volunteer_id, :presence => true, :on => :create
  validates :notification_id, :presence => true, :on => :create
end

class NotificationVolunteer < ActiveRecord::Base
  belongs_to :volunteer
  belongs_to :notification

  validates :volunteer_id, :presence => true, :on => :create
  validates :notification_id, :presence => true, :on => :create
end

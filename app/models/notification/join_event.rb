class Notification::JoinEvent < ActiveRecord::Base
  validates :volunteer_id, presence: true, :on => :create
  validates :event_id, presence: true, :on => :create
end

class Notification::InviteGuest < ActiveRecord::Base
  validates :event_id, presence: true, :on => :create
  validates :volunteer_id, presence: true, :on => :create
end

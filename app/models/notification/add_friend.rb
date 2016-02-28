class Notification::AddFriend < ActiveRecord::Base
  validates :sender_volunteer_id, presence: true, :on => :create
  validates :receiver_volunteer_id, presence: true, :on => :create
end

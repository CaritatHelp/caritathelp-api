class VFriend < ActiveRecord::Base
  validates :current_volunteer_id, presence: true, :on => :create
  validates :friend_volunteer_id, presence: true, :on => :create
end

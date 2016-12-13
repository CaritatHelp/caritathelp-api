class VFriend < ActiveRecord::Base
  belongs_to :volunteer, foreign_key: 'friend_volunteer_id'

  validates :volunteer_id, presence: true, :on => :create
  validates :friend_volunteer_id, presence: true, :on => :create
end

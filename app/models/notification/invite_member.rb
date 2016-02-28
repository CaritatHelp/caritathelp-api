class Notification::InviteMember < ActiveRecord::Base
  validates :sender_assoc_id, presence: true, :on => :create
  validates :receiver_volunteer_id, presence: true, :on => :create
end

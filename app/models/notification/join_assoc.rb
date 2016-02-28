class Notification::JoinAssoc < ActiveRecord::Base
  validates :sender_volunteer_id, presence: true, :on => :create
  validates :receiver_assoc_id, presence: true, :on => :create
end

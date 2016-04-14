class ChatroomVolunteer < ActiveRecord::Base
  validates :chatroom_id, presence: true, :on => :create
  validates :volunteer_id, presence: true, :on => :create
end

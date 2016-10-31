class Chatroom < ActiveRecord::Base
  has_many :volunteers, through: :chatroom_volunteers
  has_many :messages, dependent: :destroy
  has_many :chatroom_volunteers, dependent: :destroy

  validates :is_private, :inclusion => {:in => [true, false]}, :on => :create

  def read_by? volunteer
  	link = self.chatroom_volunteers.select { |link| link.volunteer_id == volunteer.id }.first
  	return link.read if link.present?
  	return false
  end

  def set_as_read_by volunteer
  	link = self.chatroom_volunteers.select { |link| link.volunteer_id == volunteer.id }.first
  	link.read = true if link.present?
  	link.save
  end

  def set_as_unread
  	self.chatroom_volunteers.each do |link|
  		link.read = false
  		link.save
  	end
  end
end

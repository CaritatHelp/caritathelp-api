class Chatroom < ActiveRecord::Base
  has_many :volunteers, through: :chatroom_volunteers
  has_many :messages, dependent: :destroy
  has_many :chatroom_volunteers, dependent: :destroy

  validates :is_private, :inclusion => {:in => [true, false]}, :on => :create
end

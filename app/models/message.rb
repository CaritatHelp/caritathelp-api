class Message < ActiveRecord::Base
  belongs_to :chatroom
  belongs_to :volunteer

  validates :chatroom_id, presence: true, :on => :create
  validates :volunteer_id, presence: true, :on => :create
  validates :content, presence: true, :on => :create
end

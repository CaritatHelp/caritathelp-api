class Event < ActiveRecord::Base
  has_and_belongs_to_many :volunteers, join_table: :event_volunteers
  has_many :event_volunteers

  validates :title, presence: true, :on => :create
  validates :description, presence: true, :on => :create
  validates :assoc_id, presence: true, :on => :create
end

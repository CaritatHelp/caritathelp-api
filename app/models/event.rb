class Event < ActiveRecord::Base
  has_and_belongs_to_many :volunteers, join_table: :event_volunteers
  has_many :event_volunteers

  before_create :set_default_picture

  validates :title, presence: true, :on => :create
  validates :description, presence: true, :on => :create
  validates :assoc_id, presence: true, :on => :create

  def set_default_picture
    self.thumb_path = Rails.application.config.logo
  end
  
end

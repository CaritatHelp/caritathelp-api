class Event < ActiveRecord::Base
  has_and_belongs_to_many :volunteers, join_table: :event_volunteers
  has_many :event_volunteers

  has_many :news, as: :group, class_name: 'New'
  
  before_create :set_default_picture
  before_save :are_dates_corrects?

  validates :title, presence: true, :on => :create
  validates :description, presence: true, :on => :create
  validates :assoc_id, presence: true, :on => :create
  validates :begin, presence: true, :on => :create
  validates :end, presence: true, :on => :create

  def set_default_picture
    self.thumb_path = Rails.application.config.logo
  end

  def are_dates_corrects?
    if self.begin < Time.now
      self.errors.add(:begin, "Can't be before now") and return false
    end
    if self.end < self.begin
      self.errors.add(:end, "Can't be before start date") and return false
    end
  end
end

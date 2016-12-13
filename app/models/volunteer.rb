class Volunteer < ActiveRecord::Base
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :trackable, :validatable, :omniauthable
  include DeviseTokenAuth::Concerns::User

  has_many :chatrooms, through: :chatroom_volunteers
  has_many :chatroom_volunteers, dependent: :destroy

  has_many :notifications, through: :notification_volunteers
  has_many :notifications, foreign_key: 'sender_id'
  has_many :notification_volunteers, dependent: :destroy

  has_many :comments, dependent: :destroy

  has_and_belongs_to_many :assocs, join_table: :av_links
  has_many :av_links, dependent: :destroy

  has_and_belongs_to_many :events, join_table: :event_volunteers
  has_many :event_volunteers, dependent: :destroy

  has_and_belongs_to_many :volunteers, join_table: :v_friends, foreign_key: 'friend_volunteer_id'
  has_many :v_friends, dependent: :destroy

  has_many :news, as: :group, class_name: 'New', dependent: :destroy

  require 'securerandom'

  VALID_EMAIL_REGEX = /\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/

  before_create :set_default_picture
  before_save :set_fullname
  before_update :check_email

  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, :on => :create
  validates :firstname, presence: true, :on => :create
  validates :lastname, presence: true, :on => :create

  validates :email, format: { with: VALID_EMAIL_REGEX }, :on => :update

  validates_inclusion_of :gender, :in => ['m', 'f'], :allow_nil => true
  validates_inclusion_of :allowgps, :in => [true, false], :allow_nil => true
  validates_inclusion_of :allow_notifications, :in => [true, false], :allow_nil => true

  def check_email
    user = self.class.find_by(email: self.email)
    if user.present? and user.id != self.id
      errors.add(:email, "already in use")
      return false
    end
    return true
  end

  def token_validation_response
    self.as_json(except: [:tokens, :created_at, :updated_at, :nickname])
      .merge(notifications_number:  self.notifications.count)
  end

  def set_default_picture
    if self.gender.eql?('f') and self.thumb_path.eql?(nil)
      self.thumb_path = Rails.application.config.default_thumb_female
    elsif self.thumb_path.eql?(nil)
      self.thumb_path = Rails.application.config.default_thumb_male
    end
  end

  def set_fullname
    self.fullname = self.firstname + " " + self.lastname
  end

  def distance_from_event_in_km(event)
    distance = Haversine.distance(event.latitude, event.longitude,
                                  self.latitude, self.longitude)
    Haversine.to_km(distance)
  end

  def distance_from_event_in_miles(event)
    distance = Haversine.distance(event.latitude, event.longitude,
                                  self.latitude, self.longitude)
    Haversine.to_miles(distance)
  end

  def self.exist?(email)
    if Volunteer.find_by(email: email).eql? nil
      return false
    end
    return true
  end

  def self.is_new_email_available?(new_email, old_email)
    if new_email.eql?(old_email) || !Volunteer.exist?(new_email)
      return true
    end
    return false
  end

  def is_allowed_to_post_on?(object_id, klass_name)
    klass = klass_name.classify.safe_constantize
    if klass.present?
      object = klass.find_by(id: object_id)
      if object.present?
        return true if object.volunteers.include?(self) or object == self
      end
    end
    return false
  end
end

class Volunteer < ActiveRecord::Base
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :trackable, :validatable, :omniauthable
  include DeviseTokenAuth::Concerns::User

  has_many :chatrooms, through: :chatroom_volunteers
  has_many :chatroom_volunteers

  has_many :notifications, through: :notification_volunteers
  has_many :notification_volunteers

  has_many :comments

  has_and_belongs_to_many :assocs, join_table: :av_links
  has_many :av_links

  has_and_belongs_to_many :events, join_table: :event_volunteers
  has_many :event_volunteers

  has_and_belongs_to_many :volunteers, join_table: :v_friends
  has_many :v_friends
  
  has_many :news, as: :group, class_name: 'New'
  
  require 'securerandom'

  VALID_EMAIL_REGEX = /\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/

  before_create :set_default_picture
  before_save :set_fullname
  # before_save :set_token
  
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, :on => :create
  validates :firstname, presence: true, :on => :create
  validates :lastname, presence: true, :on => :create

  validates :email, format: { with: VALID_EMAIL_REGEX }, :on => :update

  validates_inclusion_of :gender, :in => ['m', 'f'], :allow_nil => true
  validates_inclusion_of :allowgps, :in => [true, false], :allow_nil => true
  validates_inclusion_of :allow_notifications, :in => [true, false], :allow_nil => true

  def set_default_picture
    if self.gender.eql?('f') and self.thumb_path.eql?(nil)
      self.thumb_path = Rails.application.config.default_thumb_female
    elsif self.thumb_path.eql?(nil)
      self.thumb_path = Rails.application.config.default_thumb_male
    end
  end

  # def set_token
  #   self.token = self.tokens.values.last[:token] if self.tokens.count > 0 
  # end

  def set_fullname
    self.fullname = self.firstname + " " + self.lastname
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
end

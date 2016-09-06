class Volunteer < ActiveRecord::Base
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
  VALID_PWD_REGEX = /\A(?=.*[a-zA-Z])(?=.*[0-9]).{6,}\z/

  before_create :generate_token
  before_create :set_default_picture
  before_save :set_fullname
  
  validates :mail, presence: true, format: { with: VALID_EMAIL_REGEX }, :on => :create
  validates :password, presence: true, format: { with: VALID_PWD_REGEX }, :on => :create
  validates :firstname, presence: true, :on => :create
  validates :lastname, presence: true, :on => :create

  validates :mail, format: { with: VALID_EMAIL_REGEX }, :on => :update
  validates :password, format: { with: VALID_PWD_REGEX }, :on => :update

  validates_inclusion_of :gender, :in => ['m', 'f'], :allow_nil => true
  validates_inclusion_of :allowgps, :in => [true, false], :allow_nil => true
  validates_inclusion_of :allow_notifications, :in => [true, false], :allow_nil => true
  
  def generate_token
    generation = loop do
      self.token = SecureRandom.urlsafe_base64
      break self.token unless Volunteer.exists?(token: self.token)
    end
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

  def password= value
    if value != nil
      write_attribute :password, Digest::SHA2.hexdigest(value)
    else
      write_attribute :password, nil
    end
  end
  
  def self.exist?(mail)
    if Volunteer.find_by(mail: mail).eql? nil
      return false
    end
    return true
  end

  def self.is_new_mail_available?(new_mail, old_mail)
    if new_mail.eql?(old_mail) || !Volunteer.exist?(new_mail)
      return true
    end
    return false
  end
end

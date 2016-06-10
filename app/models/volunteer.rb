class Volunteer < ActiveRecord::Base
  has_many :chatrooms, through: :chatroom_volunteers
  has_many :chatroom_volunteers

  has_many :notifications, through: :notification_volunteers
  has_many :notification_volunteers

  has_and_belongs_to_many :assocs, join_table: :av_links
  has_many :av_links

  has_and_belongs_to_many :events, join_table: :event_volunteers
  has_many :event_volunteers

  has_and_belongs_to_many :volunteers, join_table: :v_friends
  has_many :v_friends

  require 'securerandom'

  VALID_EMAIL_REGEX = /\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/
  VALID_PWD_REGEX = /\A(?=.*[a-zA-Z])(?=.*[0-9]).{6,}\z/

  before_create :generate_token
  
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

  def password= value
    if value != nil
      write_attribute :password, Digest::SHA2.hexdigest(value)
    else
      write_attribute :password, nil
    end
  end

  def short_description(value = nil, key = "notif_id")
    if value.eql? nil
      {'id' => self.id, 'mail' => self.mail, 'firstname' => self.firstname,
        'lastname' => self.lastname}
    else
      {key => value, 'id' => self.id, 'mail' => self.mail,
        'firstname' => self.firstname, 'lastname' => self.lastname}
    end
  end

  def simple_description(friendship)
    {'id' => self.id, 'mail' => self.mail, 'firstname' => self.firstname,
      'lastname' => self.lastname, 'birthday' => self.birthday,
      'gender' => self.gender, 'city' => self.city,
      'latitude' => self.latitude, 'longitude' => self.longitude,
      'allowgps' => self.allowgps, 'allow_notifications' => self.allow_notifications,
      'friendship' => friendship}
  end

  def complete_description
    {'id' => self.id, 'mail' => self.mail,
      'token' => self.token, 'firstname' => self.firstname,
      'lastname' => self.lastname, 'birthday' => self.birthday,
      'gender' => self.gender, 'city' => self.city,
      'latitude' => self.latitude, 'longitude' => self.longitude,
      'allowgps' => self.allowgps, 'allow_notifications' => self.allow_notifications}
  end

  # gerer les exception
  # a modifier
  def friends
    friend_list = []
    VFriend.where(volunteer_id: self.id).each do |link|
      friend = Volunteer.find_by(id: link.friend_volunteer_id)
      friend_list.push friend.short_description
    end
    friend_list
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

class Notification < ActiveRecord::Base
  before_create :set_read

  has_many :volunteers, through: :notification_volunteers
  has_many :notification_volunteers

  validates :sender_id, presence: true, :on => :create
  validates :notif_type, presence: true, :on => :create
  validates :receiver_id, presence: true, :on => :create, :if => :single_receiver?
  validates :assoc_id, presence: true, :on => :create, :if => :assoc_expected?
  validates :event_id, presence: true, :on => :create, :if => :event_expected?

  def assoc_expected?
    self.notif_type.eql?('JoinAssoc') or self.notif_type.eql?('InviteMember')
  end

  def event_expected?
    self.notif_type.eql?('JoinEvent') or self.notif_type.eql?('InviteGuest')
  end

  def single_receiver?
    self.notif_type.eql?('InviteMember') or self.notif_type.eql?('InviteGuest') or self.notif_type.eql?('AddFriend')
  end

  def set_read
    self.read = false
  end
end

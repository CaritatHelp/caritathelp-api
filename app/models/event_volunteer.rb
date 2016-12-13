class EventVolunteer < ActiveRecord::Base
  enum levels: { host: 10, admin: 8, member: 5}

  belongs_to :event
  belongs_to :volunteer

  before_save :check_nil
  before_save :set_level

  validates_inclusion_of :rights, :in => ['host', 'admin', 'member'], :allow_nil => true
  validates :event_id, presence: true, :on => :create
  validates :volunteer_id, presence: true, :on => :create

  def check_nil
    if self.rights.eql? nil
      self.rights = 'member'
    end
  end

  def set_level
    if self.rights.eql? 'host'
      self.level = EventVolunteer.levels["host"]
    elsif self.rights.eql? 'admin'
      self.level = EventVolunteer.levels["admin"]
    else
      self.level = EventVolunteer.levels["member"]
    end
  end
end

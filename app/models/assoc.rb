class Assoc < ActiveRecord::Base
  has_and_belongs_to_many :volunteers, join_table: :av_links
  has_many :av_links

  validates :name, presence: true, :on => :create
  validates :description, presence: true, :on => :create

  def short_description(value = nil, key = "notif_id")
    if value.eql? nil
      {'id' => self.id, 'name' => self.name, 'city' => self.city}
    else
      {key => value, 'id' => self.id, 'name' => self.name, 'city' => self.city}
    end
  end

  def complete_description
    {'id' => self.id, 'name' => self.name, 'description' => self.description,
      'city' => self.city, 'birthday' => self.birthday,
      'latitude' => self.latitude, 'longitude' => self.longitude}
  end

  # need to handle possible exception
  def notifications
    notif_member_list = []
    Notification::JoinAssoc.where(receiver_assoc_id: self.id).each do |link|
      sender = Volunteer.find_by(id: link.sender_volunteer_id)
      notif_member_list.push sender.short_description(link.id)
    end
    {'member_request' => notif_member_list}
  end

  def events
    events_list = []
    Event.where(assoc_id: self.id).each do |link|
      events_list.push link.short_description
    end
    events_list
  end

  def self.exist?(name)
    if Assoc.find_by(name: name).eql? nil
      return false
    end
    return true
  end

  def self.is_new_name_available?(new_name, old_name)
    if new_name.eql?(old_name) || !Assoc.exist?(new_name)
      return true
    end
    return false
  end
end

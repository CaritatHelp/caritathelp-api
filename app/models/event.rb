class Event < ActiveRecord::Base
  has_and_belongs_to_many :volunteers, join_table: :event_volunteers
  has_many :event_volunteers

  validates :title, presence: true, :on => :create
  validates :description, presence: true, :on => :create
  validates :assoc_id, presence: true, :on => :create

  def short_description(value = nil, key = "notif_id")
    if value.eql? nil
      {'id' => self.id, 'title' => self.title, 'place' => self.place}
    else
      {key => value, 'id' => self.id, 'title' => self.title, 'place' => self.place}
    end
  end

  def complete_description
    {'id' => self.id, 'title' => self.title, 'description' => self.description,
      'place' => self.place, 'begin' => self.begin,
      'end' => self.end, 'assoc_id' => self.assoc_id}
  end

  # need to handle possible exception
  def notifications
    notif_guest_list = []
    Notification::JoinEvent.where(event_id: self.id).each do |link|
      sender = Volunteer.find_by(id: link.volunteer_id)
      notif_guest_list.push sender.short_description(link.id)
    end
    {'guest_request' => notif_guest_list}
  end
end

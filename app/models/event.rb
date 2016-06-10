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

  def complete_description(rights = 'none')
    {'id' => self.id, 'title' => self.title, 'description' => self.description,
      'place' => self.place, 'begin' => self.begin,
      'end' => self.end, 'assoc_id' => self.assoc_id, 'rights' => rights}
  end
end

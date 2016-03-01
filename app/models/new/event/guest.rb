class New::Event::Guest < New::New
  validates :event_id, presence: true, :on => :create
  validates :volunteer_id, presence: true, :on => :create

  def complete_description
    {'type' => self.type, 'object' =>
      {'id' => self.id, 'event_id' => self.event_id, 'volunteer_id' => self.volunteer_id}}
  end
end

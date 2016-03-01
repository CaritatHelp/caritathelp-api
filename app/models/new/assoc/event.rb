class New::Assoc::Event < New::New
  validates :assoc_id, presence: true, :on => :create
  validates :event_id, presence: true, :on => :create

  def complete_description
    {{'type' => self.type, 'object' =>
        {'id' => self.id, 'assoc_id' => self.assoc_id, 'event_id' => self.event_id}}
  end
end

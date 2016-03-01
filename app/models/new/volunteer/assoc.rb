class New::Volunteer::Assoc < New::New
  validates :volunteer_id, presence: true, :on => :create
  validates :assoc_id, presence: true, :on => :create

  def complete_description
    {'type' => self.type, 'object' =>
      {'id' => self.id, 'volunteer_id' => self.volunteer_id, 'assoc_id' => self.assoc_id}}
  end
end

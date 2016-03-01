class New::Assoc::Member < New::New
  validates :assoc_id, presence: true, :on => :create
  validates :volunteer_id, presence: true, :on => :create

  def complete_description
    {'type' => self.type, 'object' =>
      {'id' => self.id, 'assoc_id' => self.assoc_id, 'volunteer_id' => self.volunteer_id}}
  end
end

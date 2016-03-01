class New::Volunteer::Status < New::New
  validates :volunteer_id, presence: true, :on => :create
  validates :content, presence: true, :on => :create
  validates_length_of :content, :minimum => 1, :allow_blank => false

  def complete_description
    {'type' => self.type, 'object' =>
      {'id' => self.id, 'volunteer_id' => self.volunteer_id,'content' => self.content}}
  end
end

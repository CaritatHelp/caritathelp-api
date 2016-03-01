class New::Volunteer::Friend < New::New
  validates :volunteer_id, presence: true, :on => :create
  validates :friend_id, presence: true, :on => :create

  def complete_description
    {'type' => self.type, 'object' =>
      {'id' => self.id, 'volunteer_id' => self.volunteer_id, 'friend_id' => self.friend_id}}
  end
end

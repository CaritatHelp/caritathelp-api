class New::Assoc::Status < New::New
  validates :assoc_id, presence: true, :on => :create
  validates :content, presence: true, :on => :create
  validates_length_of :content, :minimum => 1, :allow_blank => false

  def complete_description
    {'type' => self.type, 'object' =>
      {'id' => self.id, 'assoc_id' => self.assoc_id, 'content' => self.content}}
  end
end

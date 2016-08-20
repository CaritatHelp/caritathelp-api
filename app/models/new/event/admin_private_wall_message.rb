class New::Event::AdminPrivateWallMessage < New::New
  validates :volunteer_id, presence: true, :on => :create
  validates :event_id, presence: true, :on => :create
  validates :content, presence: true, :on => :create
  validates_length_of :content, :minimum => 1, :allow_blank => false

  before_create :set_privacy

  private 

  def set_privacy
  	self.private = true
  end
end

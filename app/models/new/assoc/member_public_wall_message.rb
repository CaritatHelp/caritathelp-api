class New::Assoc::MemberPublicWallMessage < New::New
  validates :volunteer_id, presence: true, :on => :create
  validates :assoc_id, presence: true, :on => :create
  validates :content, presence: true, :on => :create
  validates_length_of :content, :minimum => 1, :allow_blank => false
end

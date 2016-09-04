class Comment < ActiveRecord::Base
  belongs_to :volunteer
  belongs_to :new
  
  validates :new_id, presence: true, :on => :create
  validates :volunteer_id, presence: true, :on => :create
  validates :content, presence: true, :on => [:create, :update]
  validates_length_of :content, :minimum => 1, :allow_blank => false
  
  def complete_description
    {'id' => self.id, 'volunteer_id' => self.volunteer_id,
      'new_id' => self.new_id, 'content' => self.content}
  end
end

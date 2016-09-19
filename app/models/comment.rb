class Comment < ActiveRecord::Base
  belongs_to :volunteer
  belongs_to :new
  
  validates :new_id, presence: true, :on => :create
  validates :volunteer_id, presence: true, :on => :create
  validates :content, presence: true, :on => [:create, :update]
  validates_length_of :content, :minimum => 1, :allow_blank => false

  after_create :increment_news_number_comments
  before_destroy :decrement_news_number_comments

  private

  def increment_news_number_comments
    self.new.number_comments += 1
    self.new.save
  end

  def decrement_news_number_comments
    self.new.number_comments -= 1 unless self.new.number_comments == 0
    self.new.save
  end
end

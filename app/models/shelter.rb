class Shelter < ActiveRecord::Base
  serialize :tags, Array
  
  validates :name, presence: true, :on => :create
  validates :address, presence: true, :on => :create
  validates :zipcode, presence: true, :on => :create
  validates :city, presence: true, :on => :create
  validates :total_places, :numericality => { :greater_than_or_equal_to => 0},
  presence: true, :on => :create
  validates :free_places, :numericality => { :greater_than_or_equal_to => 0},
  presence: true, :on => :create
  validate :if_free_correct

  private 

  def if_free_correct
    errors.add(:free_places, "free_places value must be lower or equal to total_places") unless
      free_places != nil and total_places != nil and free_places <= total_places
  end
end

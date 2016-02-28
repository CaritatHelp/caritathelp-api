class AvLink < ActiveRecord::Base
  before_save :check_nil
  before_save :set_level

  validates_inclusion_of :rights, :in => ['owner', 'admin', 'member'], :allow_nil => true
  validates :assoc_id, presence: true, :on => :create
  validates :volunteer_id, presence: true, :on => :create

  def check_nil
    if self.rights.eql? nil
      self.rights = 'member'
    end
  end

  def set_level
    if self.rights.eql? 'owner'
      self.level = 3
    elsif self.rights.eql? 'admin'
      self.level = 2
    else
      self.level = 1
    end
  end
end

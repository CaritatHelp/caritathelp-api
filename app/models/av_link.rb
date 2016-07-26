class AvLink < ActiveRecord::Base
  enum levels: { owner: 10, admin: 8, member: 5, follower: 0, block: -10} 
  before_save :check_nil
  before_save :set_level

  validates_inclusion_of :rights, :in => ['owner', 'admin', 'member', 'follower', 'block'], :allow_nil => true
  validates :assoc_id, presence: true, :on => :create
  validates :volunteer_id, presence: true, :on => :create

  def check_nil
    if self.rights.eql? nil
      self.rights = 'member'
    end
  end

  def set_level
    if self.rights.eql? 'owner'
      self.level = AvLink.levels["owner"]
    elsif self.rights.eql? 'admin'
      self.level = AvLink.levels["admin"]
    elsif self.rights.eql? 'member'
      self.level = AvLink.levels["member"]
    elsif self.rights.eql? 'follower'
      self.level = AvLink.levels["follower"]
    else
      self.level = AvLink.levels["block"]
    end
  end
end

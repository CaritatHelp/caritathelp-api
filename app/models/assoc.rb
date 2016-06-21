class Assoc < ActiveRecord::Base
  has_and_belongs_to_many :volunteers, join_table: :av_links
  has_many :av_links

  validates :name, presence: true, :on => :create
  validates :description, presence: true, :on => :create

  def self.exist?(name)
    if Assoc.find_by(name: name).eql? nil
      return false
    end
    return true
  end

  def self.is_new_name_available?(new_name, old_name)
    if new_name.eql?(old_name) || !Assoc.exist?(new_name)
      return true
    end
    return false
  end
end

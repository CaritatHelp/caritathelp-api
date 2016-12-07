class Assoc < ActiveRecord::Base
  has_and_belongs_to_many :volunteers, join_table: :av_links

  has_many :shelters

  has_many :av_links

  has_many :events
  
  has_many :news, as: :group, class_name: 'New', dependent: :destroy
  
  before_create :set_default_picture

  validates :name, presence: true, :on => :create
  validates :description, presence: true, :on => :create

  def set_default_picture
    self.thumb_path = Rails.application.config.logo
  end

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

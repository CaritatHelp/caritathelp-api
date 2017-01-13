class New < ActiveRecord::Base
  belongs_to :group, polymorphic: true
  has_many :comments, dependent: :destroy

  validates :volunteer_id, presence: true, on: :create
  validates :news_type, presence: true, on: :create
  validates :group_id, presence: true, on: :create
  validates :group_type, presence: true, on: :create
  validates :group, presence: true, on: :create
  validates_inclusion_of :news_type, in: ["Status"]
  validates_inclusion_of :group_type, in: ["Assoc", "Event", "Volunteer"]

  def public
    !self.private
  end

  def concerns_user?(volunteer)
    return true unless self.private
    return true if self.volunteer_id == volunteer.id

    class_type = self.group_type.classify.safe_constantize
    if class_type.present?
      group = class_type.find_by(id: self.group_id)
      return true if group.present? and group.volunteers.include?(volunteer)
    end
    return false
  end
end

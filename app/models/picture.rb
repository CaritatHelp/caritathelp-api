class Picture < ActiveRecord::Base
  mount_uploader :picture_path, FileUploader

  before_save :update_pictures_attributes

  validates :volunteer_id, presence: true, :on => :create

  def update_pictures_attributes
    self.file_size = picture_path.file.size
  end
end

class ModifyPicturesPathFields < ActiveRecord::Migration
  def change
    add_column :pictures, :path, :string
    add_column :pictures, :thumb_path, :string
  end
end

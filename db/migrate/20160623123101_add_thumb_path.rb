class AddThumbPath < ActiveRecord::Migration
  def change
    add_column :volunteers, :thumb_path, :string
    add_column :assocs, :thumb_path, :string
    add_column :events, :thumb_path, :string
  end
end

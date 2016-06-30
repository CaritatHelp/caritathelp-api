class AddThumbPathToNotif < ActiveRecord::Migration
  def change
    add_column :notifications, :thumb_path, :string
  end
end

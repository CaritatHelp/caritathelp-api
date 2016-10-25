class AddReceiverThumbPathToNotification < ActiveRecord::Migration
  def change
    add_column :notifications, :receiver_thumb_path, :string
    rename_column :notifications, :thumb_path, :sender_thumb_path
  end
end

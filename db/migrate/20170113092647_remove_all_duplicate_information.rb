class RemoveAllDuplicateInformation < ActiveRecord::Migration
  def change
    # remove events duplicate info
    remove_column :events, :assoc_name

    # remove news duplicate info
    remove_column :news, :group_name
    remove_column :news, :group_thumb_path
    remove_column :news, :volunteer_name
    remove_column :news, :volunteer_thumb_path

    # remove notifications duplicate info
    remove_column :notifications, :assoc_name
    remove_column :notifications, :event_name
    remove_column :notifications, :sender_name
    remove_column :notifications, :receiver_name
    remove_column :notifications, :sender_thumb_path
    remove_column :notifications, :receiver_thumb_path
  end
end

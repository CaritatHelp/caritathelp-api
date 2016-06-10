class ModifyNotifFields < ActiveRecord::Migration
  def change
    rename_column :notifications, :volunteer_id, :sender_id
    rename_column :notifications, :friend_id, :receiver_id
  end
end

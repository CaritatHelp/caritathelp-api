class DeleteAllNotificationTables < ActiveRecord::Migration
  def change
    drop_table :notification_add_friends
    drop_table :notification_invite_guests
    drop_table :notification_invite_members
    drop_table :notification_join_assocs
    drop_table :notification_join_events    
  end
end

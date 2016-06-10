class RenameFieldsNotifications < ActiveRecord::Migration
  def change
    rename_column :notification_add_friends, :sender_volunteer_id, :volunteer_id
    rename_column :notification_add_friends, :receiver_volunteer_id, :friend_id
    add_column :notification_add_friends, :read, :boolean, :default => false

    rename_column :notification_invite_members, :sender_assoc_id, :assoc_id
    rename_column :notification_invite_members, :receiver_volunteer_id, :volunteer_id
    add_column :notification_invite_members, :read, :boolean, :default => false
    
    rename_column :notification_join_assocs, :sender_volunteer_id, :volunteer_id
    rename_column :notification_join_assocs, :receiver_assoc_id, :assoc_id
    add_column :notification_join_assocs, :read, :boolean, :default => false

    add_column :notification_invite_guests, :read, :boolean, :default => false
  end
end

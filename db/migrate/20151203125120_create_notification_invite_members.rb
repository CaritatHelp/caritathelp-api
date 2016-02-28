class CreateNotificationInviteMembers < ActiveRecord::Migration
  def change
    create_table :notification_invite_members do |t|
      t.integer :sender_assoc_id
      t.integer :receiver_volunteer_id
      t.boolean :acceptance

      t.timestamps null: false
    end
  end
end

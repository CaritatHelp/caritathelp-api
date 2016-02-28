class CreateNotificationAddFriends < ActiveRecord::Migration
  def change
    create_table :notification_add_friends do |t|
      t.integer :sender_volunteer_id
      t.integer :receiver_volunteer_id
      t.boolean :acceptance

      t.timestamps null: false
    end
  end
end

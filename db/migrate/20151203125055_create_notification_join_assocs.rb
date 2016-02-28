class CreateNotificationJoinAssocs < ActiveRecord::Migration
  def change
    create_table :notification_join_assocs do |t|
      t.integer :sender_volunteer_id
      t.integer :receiver_assoc_id
      t.boolean :acceptance

      t.timestamps null: false
    end
  end
end

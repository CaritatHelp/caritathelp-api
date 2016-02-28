class CreateNotificationInviteGuests < ActiveRecord::Migration
  def change
    create_table :notification_invite_guests do |t|
      t.integer :volunteer_id
      t.integer :event_id

      t.timestamps null: false
    end
  end
end

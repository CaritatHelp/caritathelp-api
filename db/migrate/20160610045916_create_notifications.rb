class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :volunteer_id
      t.integer :friend_id
      t.integer :assoc_id
      t.integer :event_id
      t.boolean :read, default: false
      t.string :notif_type

      t.timestamps null: false
    end
  end
end

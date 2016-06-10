class CreateNotificationVolunteers < ActiveRecord::Migration
  def change
    create_table :notification_volunteers do |t|
      t.integer :notification_id
      t.integer :volunteer_id
      t.boolean :read

      t.timestamps null: false
    end
  end
end

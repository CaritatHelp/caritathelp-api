class CreateEventVolunteers < ActiveRecord::Migration
  def change
    create_table :event_volunteers do |t|
      t.integer :event_id
      t.integer :volunteer_id
      t.string :rights

      t.timestamps null: false
    end
  end
end

class CreateChatroomVolunteers < ActiveRecord::Migration
  def change
    create_table :chatroom_volunteers do |t|
      t.integer :chatroom_id
      t.integer :volunteer_id

      t.timestamps null: false
    end
  end
end

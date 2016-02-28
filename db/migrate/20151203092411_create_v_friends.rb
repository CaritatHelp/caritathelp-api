class CreateVFriends < ActiveRecord::Migration
  def change
    create_table :v_friends do |t|
      t.integer :current_volunteer_id
      t.integer :friend_volunteer_id

      t.timestamps null: false
    end
  end
end

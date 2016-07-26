class CreateNewVolunteerSelfWallMessages < ActiveRecord::Migration
  def change
    create_table :new_volunteer_self_wall_messages do |t|

      t.timestamps null: false
    end
  end
end

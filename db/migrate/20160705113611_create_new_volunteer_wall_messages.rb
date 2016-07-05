class CreateNewVolunteerWallMessages < ActiveRecord::Migration
  def change
    create_table :new_volunteer_wall_messages do |t|

      t.timestamps null: false
    end
  end
end

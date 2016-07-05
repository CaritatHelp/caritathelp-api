class CreateNewEventWallMessages < ActiveRecord::Migration
  def change
    create_table :new_event_wall_messages do |t|

      t.timestamps null: false
    end
  end
end

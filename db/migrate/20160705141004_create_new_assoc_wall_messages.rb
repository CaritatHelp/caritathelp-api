class CreateNewAssocWallMessages < ActiveRecord::Migration
  def change
    create_table :new_assoc_wall_messages do |t|

      t.timestamps null: false
    end
  end
end

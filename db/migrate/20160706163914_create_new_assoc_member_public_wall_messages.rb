class CreateNewAssocMemberPublicWallMessages < ActiveRecord::Migration
  def change
    create_table :new_assoc_member_public_wall_messages do |t|

      t.timestamps null: false
    end
  end
end

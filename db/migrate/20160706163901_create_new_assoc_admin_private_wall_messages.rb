class CreateNewAssocAdminPrivateWallMessages < ActiveRecord::Migration
  def change
    create_table :new_assoc_admin_private_wall_messages do |t|

      t.timestamps null: false
    end
  end
end

class CreateNewAssocAdminPublicWallMessages < ActiveRecord::Migration
  def change
    create_table :new_assoc_admin_public_wall_messages do |t|

      t.timestamps null: false
    end
  end
end

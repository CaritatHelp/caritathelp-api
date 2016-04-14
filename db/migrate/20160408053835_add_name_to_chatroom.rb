class AddNameToChatroom < ActiveRecord::Migration
  def change
    add_column :chatrooms, :name, :string
  end
end

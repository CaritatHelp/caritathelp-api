class AddPrivateToChatroom < ActiveRecord::Migration
  def change
    add_column :chatrooms, :is_private, :boolean
  end
end

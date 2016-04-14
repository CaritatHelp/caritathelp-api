class AddNumberToChatroom < ActiveRecord::Migration
  def change
    add_column :chatrooms, :number, :integer
  end
end

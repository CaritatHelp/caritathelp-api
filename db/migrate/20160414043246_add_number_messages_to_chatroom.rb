class AddNumberMessagesToChatroom < ActiveRecord::Migration
  def change
    rename_column :chatrooms, :number, :number_volunteers
    add_column :chatrooms, :number_messages, :integer
  end
end

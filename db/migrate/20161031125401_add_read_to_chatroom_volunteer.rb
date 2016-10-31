class AddReadToChatroomVolunteer < ActiveRecord::Migration
  def change
    add_column :chatroom_volunteers, :read, :boolean, default: false
  end
end

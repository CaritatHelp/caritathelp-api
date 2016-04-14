class RenameFieldVFriend < ActiveRecord::Migration
  def change
    rename_column :v_friends, :current_volunteer_id, :volunteer_id
  end
end

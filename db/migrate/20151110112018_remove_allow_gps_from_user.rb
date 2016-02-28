class RemoveAllowGpsFromUser < ActiveRecord::Migration
  def change
    remove_column :users, :allowGPS
  end
end

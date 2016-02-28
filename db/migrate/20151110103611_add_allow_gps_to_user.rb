class AddAllowGpsToUser < ActiveRecord::Migration
  def change
    add_column :users, :allowGPS, :boolean
  end
end

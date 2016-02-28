class AddAllowgpsToUser < ActiveRecord::Migration
  def change
    add_column :users, :allowgps, :boolean
  end
end

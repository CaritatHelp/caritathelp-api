class ChangeAllowgpsInUser < ActiveRecord::Migration
  def change
    change_column :users, :allowgps, :boolean, :default => false
  end
end

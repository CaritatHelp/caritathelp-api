class AddPrivateFieldToEvent < ActiveRecord::Migration
  def change
    add_column :events, :private, :boolean, default: false
  end
end

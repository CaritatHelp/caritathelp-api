class AddAssocNameToEvent < ActiveRecord::Migration
  def change
    add_column :events, :assoc_name, :string
  end
end

class AddAssocIdToShelter < ActiveRecord::Migration
  def change
    add_column :shelters, :assoc_id, :integer
    add_column :shelters, :thumb_path, :string
    add_column :shelters, :description, :string
  end
end

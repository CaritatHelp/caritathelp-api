class AddShelterIdToPictures < ActiveRecord::Migration
  def change
    add_column :pictures, :shelter_id, :integer
  end
end

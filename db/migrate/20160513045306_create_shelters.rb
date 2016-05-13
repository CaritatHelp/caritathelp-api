class CreateShelters < ActiveRecord::Migration
  def change
    create_table :shelters do |t|
      t.string :name
      t.string :address
      t.integer :zipcode
      t.string :city
      t.decimal :latitude
      t.decimal :longitude
      t.integer :total_places
      t.integer :free_places
      t.text :tags

      t.timestamps null: false
    end
  end
end

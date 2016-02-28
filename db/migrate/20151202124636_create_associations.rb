class CreateAssociations < ActiveRecord::Migration
  def change
    create_table :associations do |t|
      t.string :name
      t.text :description
      t.date :birthday
      t.string :city
      t.decimal :latitude
      t.decimal :longitude

      t.timestamps null: false
    end
  end
end

class CreatePictures < ActiveRecord::Migration
  def change
    create_table :pictures do |t|
      t.integer :file_size
      t.string :picture_path
      t.integer :event_id
      t.integer :volunteer_id
      t.integer :assoc_id
      t.boolean :is_main

      t.timestamps null: false
    end
  end
end

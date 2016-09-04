class CreateNews < ActiveRecord::Migration
  def change
    create_table :news do |t|
      t.integer :volunteer_id
      t.string :news_type
      t.string :content
      t.string :title
      t.boolean :private, default: false
      t.references :group, polymorphic: true, index: true
      t.string :group_name
      t.string :group_thumb_path
      
      t.timestamps null: false
    end
  end
end

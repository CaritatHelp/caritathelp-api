class CreateNewNews < ActiveRecord::Migration
  def change
    create_table :new_news do |t|
      t.integer :assoc_id
      t.integer :event_id
      t.integer :volunteer_id
      t.integer :friend_id
      t.string :title
      t.string :content

      t.timestamps null: false
    end
  end
end

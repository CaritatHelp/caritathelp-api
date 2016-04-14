class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.integer :chatroom_id
      t.integer :volunteer_id
      t.string :content

      t.timestamps null: false
    end
  end
end

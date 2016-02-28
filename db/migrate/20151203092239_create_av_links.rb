class CreateAvLinks < ActiveRecord::Migration
  def change
    create_table :av_links do |t|
      t.integer :association_id
      t.integer :volunteer_id
      t.string :rights

      t.timestamps null: false
    end
  end
end

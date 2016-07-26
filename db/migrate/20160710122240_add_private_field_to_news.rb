class AddPrivateFieldToNews < ActiveRecord::Migration
  def change
    add_column :new_news, :private, :boolean, default: false
  end
end

class AddTypeToNew < ActiveRecord::Migration
  def change
    add_column :new_news, :type, :string
  end
end

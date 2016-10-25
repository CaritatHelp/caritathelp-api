class AddAsGroupToNews < ActiveRecord::Migration
  def change
    add_column :news, :as_group, :boolean, default: false
    add_column :news, :volunteer_name, :string
    add_column :news, :volunteer_thumb_path, :string
  end
end

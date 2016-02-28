class AddLevelToAvLink < ActiveRecord::Migration
  def change
    add_column :av_links, :level, :integer
  end
end

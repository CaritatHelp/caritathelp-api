class AddNumberOfCommentsOnNews < ActiveRecord::Migration
  def change
    add_column :news, :number_comments, :integer, default: 0
  end
end

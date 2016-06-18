class AddNamesToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :assoc_name, :string
    add_column :notifications, :event_name, :string
    add_column :notifications, :sender_name, :string
    add_column :notifications, :receiver_name, :string
  end
end

class AddAllowNotificationToVolunteer < ActiveRecord::Migration
  def change
    add_column :volunteers, :allow_notifications, :boolean
  end
end

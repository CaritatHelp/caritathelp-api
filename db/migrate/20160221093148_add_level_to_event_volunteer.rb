class AddLevelToEventVolunteer < ActiveRecord::Migration
  def change
    add_column :event_volunteers, :level, :integer
  end
end

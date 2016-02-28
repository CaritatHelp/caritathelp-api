class RenameUserToVolunteer < ActiveRecord::Migration
  def change
    rename_table :users, :volunteers
  end
end

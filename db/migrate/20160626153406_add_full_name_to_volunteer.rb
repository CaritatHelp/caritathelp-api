class AddFullNameToVolunteer < ActiveRecord::Migration
  def change
    add_column :volunteers, :fullname, :string
  end
end

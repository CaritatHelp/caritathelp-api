class AddPhoneAndEmailToShelters < ActiveRecord::Migration
  def change
    add_column :shelters, :phone, :string
    add_column :shelters, :mail, :string
  end
end

class RenameAssociationToAssoc < ActiveRecord::Migration
  def change
    rename_table :associations, :assocs
  end
end

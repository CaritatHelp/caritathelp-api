class RenameAssociationIdInAvlink < ActiveRecord::Migration
  def change
    rename_column :av_links, :association_id, :assoc_id
  end
end

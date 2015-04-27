class CreatePendingApprovals < ActiveRecord::Migration
  def change
    create_table :pending_approvals do |t|
      t.string   :resource_type,     null: false
      t.integer  :resource_id,       null: false
      t.text     :object_changes
      t.text     :raw_object,        null: false
      t.timestamps                   null: false
    end
  end
end
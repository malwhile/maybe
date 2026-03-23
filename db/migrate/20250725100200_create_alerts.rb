class CreateAlerts < ActiveRecord::Migration[7.2]
  def change
    create_table :alerts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.string     :alert_type, null: false
      t.string     :alertable_type
      t.uuid       :alertable_id
      t.jsonb      :metadata, default: {}
      t.timestamps
    end

    add_index :alerts, [:family_id, :alert_type, :alertable_type, :alertable_id],
              unique: true,
              name: "index_alerts_uniqueness"
    add_index :alerts, [:family_id, :created_at]
  end
end

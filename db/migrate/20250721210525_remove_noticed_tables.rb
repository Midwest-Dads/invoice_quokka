class RemoveNoticedTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :noticed_notifications if table_exists?(:noticed_notifications)
    drop_table :noticed_events if table_exists?(:noticed_events)
  end

  def down
    # Recreate noticed tables if needed for rollback
    create_table :noticed_events, force: :cascade do |t|
      t.string :type
      t.string :record_type
      t.string :record_id
      t.json :params
      t.integer :notifications_count, default: 0
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index [ :record_type, :record_id ], name: "index_noticed_events_on_record"
    end

    create_table :noticed_notifications, force: :cascade do |t|
      t.string :type
      t.string :event_id, null: false
      t.string :recipient_type, null: false
      t.string :recipient_id, null: false
      t.datetime :read_at
      t.datetime :seen_at
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index [ :event_id ], name: "index_noticed_notifications_on_event_id"
      t.index [ :read_at ], name: "index_noticed_notifications_on_read_at"
      t.index [ :recipient_type, :recipient_id ], name: "index_noticed_notifications_on_recipient"
    end
  end
end

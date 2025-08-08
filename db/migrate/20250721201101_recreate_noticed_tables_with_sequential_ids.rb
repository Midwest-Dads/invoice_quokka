class RecreateNoticedTablesWithSequentialIds < ActiveRecord::Migration[8.0]
  def up
    # Drop existing tables
    drop_table :noticed_notifications if table_exists?(:noticed_notifications)
    drop_table :noticed_events if table_exists?(:noticed_events)

    # Recreate with sequential IDs
    create_table :noticed_events do |t|
      t.string :type
      t.belongs_to :record, polymorphic: true, null: true, type: :string
      if t.respond_to?(:jsonb)
        t.jsonb :params
      else
        t.json :params
      end
      t.integer :notifications_count, default: 0

      t.timestamps
    end

    create_table :noticed_notifications do |t|
      t.string :type
      t.belongs_to :event, null: false, type: :string
      t.belongs_to :recipient, polymorphic: true, null: false, type: :string
      t.datetime :read_at
      t.datetime :seen_at

      t.timestamps
    end

    add_index :noticed_notifications, :read_at
  end

  def down
    # Drop the sequential ID tables
    drop_table :noticed_notifications if table_exists?(:noticed_notifications)
    drop_table :noticed_events if table_exists?(:noticed_events)

    # Recreate with UUIDs (original structure)
    create_table :noticed_events, id: :uuid do |t|
      t.string :type
      t.belongs_to :record, polymorphic: true, type: :uuid
      if t.respond_to?(:jsonb)
        t.jsonb :params
      else
        t.json :params
      end

      t.timestamps
    end

    create_table :noticed_notifications, id: :uuid do |t|
      t.string :type
      t.belongs_to :event, null: false, type: :uuid
      t.belongs_to :recipient, polymorphic: true, null: false, type: :uuid
      t.datetime :read_at
      t.datetime :seen_at

      t.timestamps
    end

    add_index :noticed_notifications, :read_at
  end
end

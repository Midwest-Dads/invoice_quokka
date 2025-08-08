class CreateNotifications < ActiveRecord::Migration[8.0]
  def up
    create_table :notifications, id: :string do |t|
      t.references :recipient, polymorphic: true, null: false, type: :string
      t.string :notification_type
      t.text :content
      t.integer :delivery_method
      t.datetime :delivered_at

      t.timestamps
    end

    add_index :notifications, [ :recipient_type, :recipient_id ]
    add_index :notifications, :notification_type
    add_index :notifications, :delivery_method
    add_index :notifications, :delivered_at
    add_index :notifications, :created_at
  end

  def down
    drop_table :notifications
  end
end

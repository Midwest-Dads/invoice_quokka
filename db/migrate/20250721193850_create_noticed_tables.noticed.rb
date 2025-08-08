# This migration comes from noticed (originally 20231215190233)
class CreateNoticedTables < ActiveRecord::Migration[6.1]
  def change
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
  end
end

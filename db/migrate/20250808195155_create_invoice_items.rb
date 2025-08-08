class CreateInvoiceItems < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_items, id: :string do |t|
      t.references :invoice, null: false, foreign_key: true, type: :string
      t.text :description
      t.decimal :quantity
      t.decimal :unit_price

      t.timestamps
    end
  end
end

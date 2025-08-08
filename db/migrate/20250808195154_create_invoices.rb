class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices, id: :string do |t|
      t.references :user, null: false, foreign_key: true, type: :string
      t.references :client, null: false, foreign_key: true, type: :string
      t.string :invoice_number
      t.date :issue_date
      t.date :due_date
      t.integer :status
      t.decimal :tax_rate
      t.text :notes

      t.timestamps
    end
  end
end

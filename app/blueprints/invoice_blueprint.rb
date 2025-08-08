class InvoiceBlueprint < Blueprinter::Base
  identifier :id

  fields :invoice_number, :issue_date, :due_date, :status, :tax_rate, :notes, :created_at, :updated_at

  field :subtotal do |invoice|
    invoice.subtotal
  end

  field :tax_amount do |invoice|
    invoice.tax_amount
  end

  field :total_amount do |invoice|
    invoice.total_amount
  end

  association :client, blueprint: ClientBlueprint
  association :invoice_items, blueprint: InvoiceItemBlueprint
end
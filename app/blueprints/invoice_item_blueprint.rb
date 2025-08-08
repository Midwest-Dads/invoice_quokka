class InvoiceItemBlueprint < Blueprinter::Base
  identifier :id

  fields :description, :quantity, :unit_price, :created_at, :updated_at

  field :total do |invoice_item|
    invoice_item.total
  end
end
class ClientBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :email, :address, :phone, :created_at, :updated_at

  field :display_name do |client|
    client.display_name
  end
end
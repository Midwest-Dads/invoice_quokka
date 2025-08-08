# frozen_string_literal: true

require_relative "../plinth/plinth_base_generator"

class PlinthBlueprintGenerator < PlinthBaseGenerator
  source_root File.expand_path("templates", __dir__)

  def create_blueprint
    empty_directory "app/blueprints"
    template "blueprint.rb.tt", "app/blueprints/#{singular_name}_blueprint.rb"
    add_display_name_method
  end

  private

  def add_display_name_method
    model_path = File.join(destination_root, "app/models/#{singular_name}.rb")

    # Only proceed if the model file exists
    return unless File.exist?(model_path)

    model_content = File.read(model_path)

    # Only add display_name method if it doesn't exist
    unless model_content.include?("def display_name")
      inject_into_class model_path, class_name do
        <<~RUBY

          def display_name
            # TODO: Customize this method to return an appropriate display name
            #{default_display_field}
          end
        RUBY
      end
    end
  end

  def default_display_field
    # Try to find a reasonable default field for display_name
    if model_exists?
      model_class = class_name.constantize
      columns = model_class.columns.map(&:name)

      if columns.include?("name")
        "name"
      elsif columns.include?("title")
        "title"
      elsif columns.include?("email")
        "email"
      elsif columns.include?("phone_number")
        "phone_number"
      else
        "id.to_s"
      end
    else
      "id.to_s"
    end
  end


  def ensure_referenced_blueprints_exist
    reference_attributes.each do |attribute|
      referenced_model = reference_model_name(attribute)
      blueprint_path = "app/blueprints/#{referenced_model.underscore}_blueprint.rb"

      unless File.exist?(blueprint_path)
        say "Creating referenced blueprint for #{referenced_model}...", :yellow
        # Create the blueprint directly instead of calling generator
        empty_directory "app/blueprints"

        # Create a simple blueprint template inline
        blueprint_content = <<~BLUEPRINT
          # frozen_string_literal: true

          class #{referenced_model}Blueprint < Blueprinter::Base
            identifier :id

            # Add fields as needed
            # field :name
            # field :created_at
            # field :updated_at
          end
        BLUEPRINT

        create_file blueprint_path, blueprint_content
      end
    end
  end
end

# frozen_string_literal: true

module Plinth
  module Concerns
    module BlueprintHelper
      def create_blueprint_if_needed
        blueprint_path = "app/blueprints/#{singular_name}_blueprint.rb"
        return if File.exist?(blueprint_path)

        say "Creating blueprint for #{class_name}...", :green
        empty_directory "app/blueprints"
        template File.expand_path("../templates/shared/blueprint.rb.tt", __dir__), blueprint_path
        add_display_name_method_to_model
      end

      private

      def add_display_name_method_to_model
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
    end
  end
end

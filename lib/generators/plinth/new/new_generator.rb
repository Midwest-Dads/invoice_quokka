# frozen_string_literal: true

require_relative "../plinth_base_generator"
require_relative "../concerns/blueprint_helper"
require_relative "../concerns/api_controller_helper"
require_relative "../concerns/routes_helper"
require_relative "../concerns/types_helper"

module Plinth
  class NewGenerator < PlinthBaseGenerator
    include Plinth::Concerns::BlueprintHelper
    include Plinth::Concerns::ApiControllerHelper
    include Plinth::Concerns::RoutesHelper
    include Plinth::Concerns::TypesHelper

    source_root File.expand_path("templates", __dir__)

    def create_new_view
      create_types_file_if_needed
      create_blueprint_if_needed
      create_api_controller_if_needed
      add_routes_if_needed

      empty_directory "app/views/#{plural_name}"
      template "new.html.erb.tt", "app/views/#{plural_name}/new.html.erb"
    end

    def create_new_component
      empty_directory "app/javascript/components/#{plural_name}"
      template "Create.tsx.tt", "app/javascript/components/#{plural_name}/#{class_name}Create.tsx"
    end

    def create_controller_action
      controller_path = "app/controllers/#{controller_file_name}_controller.rb"

      unless File.exist?(controller_path)
        template "controller.rb.tt", controller_path
      else
        # Add new action if it doesn't exist
        controller_content = File.read(controller_path)
        unless controller_content.include?("def new")
          inject_into_class controller_path, controller_class_name do
            <<~RUBY
              def new
                @#{singular_name} = #{class_name}.new
              #{unique_reference_collections.map { |collection| "    @#{collection} = #{collection.classify}.all" }.join("\n")}
              end

            RUBY
          end
        end
      end
    end
  end
end

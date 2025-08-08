# frozen_string_literal: true

module Plinth
  module Concerns
    module ApiControllerHelper
      def create_api_controller_if_needed
        api_controller_path = "app/controllers/api/v1/#{controller_file_name}_controller.rb"
        return if File.exist?(api_controller_path)

        say "Creating API controller for #{class_name}...", :green
        empty_directory "app/controllers/api/v1"
        template File.expand_path("../templates/shared/api_controller.rb.tt", __dir__), api_controller_path
      end
    end
  end
end

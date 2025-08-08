# frozen_string_literal: true

module Plinth
  module Concerns
    module TypesHelper
      def create_types_file_if_needed
        types_path = "app/javascript/types/#{plural_name}.d.ts"
        return if File.exist?(types_path)

        empty_directory "app/javascript/types"
        template File.expand_path("../templates/shared/types.ts.tt", __dir__), types_path
      end
    end
  end
end

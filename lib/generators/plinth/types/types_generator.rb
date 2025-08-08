# frozen_string_literal: true

require_relative "../plinth_base_generator"

module Plinth
  class TypesGenerator < PlinthBaseGenerator
    source_root File.expand_path("templates", __dir__)

    def create_types_file
      empty_directory "app/javascript/types"
      template "types.ts.tt", "app/javascript/types/#{plural_name}.d.ts"
    end
  end
end

# frozen_string_literal: true

module Plinth
  module Concerns
    module RoutesHelper
      def add_routes_if_needed
        route_content = <<~ROUTES
          resources :#{plural_name}, only: [:index, :show, :new, :edit]

          namespace :api do
            namespace :v1 do
              resources :#{plural_name}, only: [:index, :show, :create, :update, :destroy]
            end
          end
        ROUTES

        # Check if routes already exist
        routes_file = File.read("config/routes.rb")
        return if routes_file.include?("resources :#{plural_name}")

        say "Adding routes for #{plural_name}...", :green
        route route_content
      end
    end
  end
end

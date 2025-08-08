# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/plinth/new/new_generator"

class Plinth::NewGeneratorIsolatedTest < Rails::Generators::TestCase
  tests Plinth::NewGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  def setup
    super
    # Create a minimal routes file for the test
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    File.write(File.join(destination_root, "config/routes.rb"), <<~RUBY)
      Rails.application.routes.draw do
        # Routes will be added here
      end
    RUBY
  end

  test "generator works without nested generator calls" do
    # This test demonstrates that we can run the generator without complex mocking
    # Previously, this would have required mocking calls to:
    # - generate "plinth:types", name
    # - generate "plinth_blueprint", name

    # Now it just works directly with helper modules
    assert_nothing_raised do
      run_generator [ "Post", "title:string", "content:text" ]
    end

    # Verify the main files are created
    assert_file "app/views/posts/new.html.erb"
    assert_file "app/javascript/components/posts/PostCreate.tsx"
    assert_file "app/controllers/posts_controller.rb"

    # Verify dependencies are also created via helper modules
    assert_file "app/javascript/types/posts.d.ts"
    assert_file "app/blueprints/post_blueprint.rb"
    assert_file "app/controllers/api/v1/posts_controller.rb"
  end

  test "can test individual helper methods in isolation" do
    generator = Plinth::NewGenerator.new([ "Post" ])

    # These methods can now be tested without worrying about nested generator calls
    assert_respond_to generator, :create_types_file_if_needed
    assert_respond_to generator, :create_blueprint_if_needed
    assert_respond_to generator, :create_api_controller_if_needed
    assert_respond_to generator, :add_routes_if_needed

    # The key point is that these are simple method calls, not generator calls
    # This makes testing much easier and more predictable
  end
end

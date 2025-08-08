Rails.application.config.generators do |g|
  g.assets false
  # g.factory_bot true
  g.helper false
  g.orm :active_record, primary_key_type: :string
  g.stylesheets false
  # g.system_tests :rspec
  g.template_engine nil
  # g.test_framework :rspec
  # g.fixture_replacement :factory_bot, suffix_factory: "factory"
end

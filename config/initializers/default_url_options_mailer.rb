# Default URL options for different environments
hosts = {
  development: 'localhost:3000',
  test: 'test.example.com',
  production: 'invoice-quokka.mangrovetechnology.com'
}.freeze

protocols = {
  development: 'http',
  test: 'http',
  production: 'https'
}.freeze

Rails.application.config.to_prepare do
  # Set default URL options for routes
  Rails.application.routes.default_url_options[:host] = hosts[Rails.env.to_sym]
  Rails.application.routes.default_url_options[:protocol] = protocols[Rails.env.to_sym]

  # Set default URL options for ActionMailer
  Rails.application.config.action_mailer.default_url_options = {
    host: hosts[Rails.env.to_sym],
    protocol: protocols[Rails.env.to_sym]
  }

  # Set default URL options for ActiveStorage
  ActiveStorage::Current.url_options = {}
  ActiveStorage::Current.url_options[:host] = hosts[Rails.env.to_sym]
  ActiveStorage::Current.url_options[:protocol] = protocols[Rails.env.to_sym]
end

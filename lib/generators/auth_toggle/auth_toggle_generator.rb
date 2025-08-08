class AuthToggleGenerator < Rails::Generators::Base
  desc "Toggle between email and SMS authentication"

  argument :auth_method, type: :string, desc: "Authentication method: email or sms", required: false

  class_option :status, type: :boolean, default: false, desc: "Show current authentication method"

  def toggle_authentication
    if options[:status]
      show_current_status
      return
    end

    unless auth_method
      say_status_with_color "error", "Please specify authentication method: email or sms", :red
      say "Usage: rails generate auth_toggle [email|sms]", :yellow
      say "       rails generate auth_toggle --status", :yellow
      exit 1
    end

    validate_auth_method

    say_status_with_color "starting", "Switching to #{auth_method} authentication", :blue

    # Update application configuration
    update_application_config

    # Update routes
    update_routes

    # Run migration
    run_migration

    # Display completion message
    display_completion_message
  end

  private

  def validate_auth_method
    unless %w[email sms].include?(auth_method)
      say_status_with_color "error", "Invalid authentication method. Use 'email' or 'sms'", :red
      exit 1
    end
  end

  def show_current_status
    current_method = get_current_auth_method
    say_status_with_color "current", "Authentication method: #{current_method}", :green
  end

  def get_current_auth_method
    config_content = File.read("config/application.rb")
    if config_content.match(/config\.authentication_method = :(\w+)/)
      $1
    else
      "unknown"
    end
  end

  def update_application_config
    say_status_with_color "update", "Updating application configuration", :cyan

    config_file = "config/application.rb"
    content = File.read(config_file)

    # Update the authentication method
    updated_content = content.gsub(
      /config\.authentication_method = :\w+/,
      "config.authentication_method = :#{auth_method}"
    )

    File.write(config_file, updated_content)
    say_status_with_color "updated", "config/application.rb", :green
  end

  def update_routes
    say_status_with_color "update", "Updating routes", :cyan

    routes_content = generate_routes_content
    File.write("config/routes.rb", routes_content)

    say_status_with_color "updated", "config/routes.rb", :green
  end

  def generate_routes_content
    case auth_method
    when "email"
      generate_email_routes
    when "sms"
      generate_sms_routes
    end
  end

  def generate_email_routes
    <<~RUBY
      Rails.application.routes.draw do
        # Email authentication routes
        resource :session, only: [:new, :create, :destroy], controller: 'email/sessions'
        resource :registration, only: [:new, :create], controller: 'email/registrations'
        resources :passwords, param: :token, controller: 'email/passwords'
      #{'  '}
        # Application routes
        get "dashboard/index"
        root to: 'dashboard#index'
      #{'  '}
        # Health check
        get "up" => "rails/health#show", as: :rails_health_check
      end
    RUBY
  end

  def generate_sms_routes
    <<~RUBY
      Rails.application.routes.draw do
        # SMS authentication routes
        resource :verification, only: [:new, :edit], controller: 'sms/verifications'
        resource :session, only: [:destroy], controller: 'sms/sessions'
      #{'  '}
        # SMS API routes
        namespace :api do
          namespace :v1 do
            resources :verifications, only: [:create]
            resource :verification, only: [:update]
          end
        end
      #{'  '}
        # Application routes
        get "dashboard/index"
        root to: 'dashboard#index'
      #{'  '}
        # Health check
        get "up" => "rails/health#show", as: :rails_health_check
      end
    RUBY
  end

  def run_migration
    say_status_with_color "migrate", "Running database migration", :cyan

    case auth_method
    when "email"
      generate_and_run_migration("ConvertToEmailAuth", email_migration_content)
    when "sms"
      generate_and_run_migration("ConvertToSmsAuth", sms_migration_content)
    end
  end

  def generate_and_run_migration(class_name, content)
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
    # Add timestamp to class name to prevent duplicates
    unique_class_name = "#{class_name}#{timestamp}"
    # Also add timestamp to filename to match class name
    migration_file = "db/migrate/#{timestamp}_#{unique_class_name.underscore}.rb"

    # Update content with unique class name
    updated_content = content.gsub("class #{class_name}", "class #{unique_class_name}")

    File.write(migration_file, updated_content)
    say_status_with_color "created", migration_file, :green

    # Run the migration
    rails_command "db:migrate"
    say_status_with_color "migrated", "Database updated", :green
  end

  def email_migration_content
    <<~RUBY
      class ConvertToEmailAuth < ActiveRecord::Migration[8.0]
        def up
          # Clear all users as requested
          User.destroy_all
      #{'    '}
          # Remove SMS field if it exists
          if column_exists?(:users, :phone_number)
            remove_index :users, :phone_number if index_exists?(:users, :phone_number)
            remove_column :users, :phone_number
          end
      #{'    '}
          # Add email fields if they don't exist
          unless column_exists?(:users, :email_address)
            add_column :users, :email_address, :string, null: false
            add_index :users, :email_address, unique: true
          end
      #{'    '}
          unless column_exists?(:users, :password_digest)
            add_column :users, :password_digest, :string, null: false
          end
        end

        def down
          # Clear all users
          User.destroy_all
      #{'    '}
          # Remove email fields
          if column_exists?(:users, :email_address)
            remove_index :users, :email_address if index_exists?(:users, :email_address)
            remove_column :users, :email_address
          end
      #{'    '}
          if column_exists?(:users, :password_digest)
            remove_column :users, :password_digest
          end
      #{'    '}
          # Add SMS field
          unless column_exists?(:users, :phone_number)
            add_column :users, :phone_number, :string, null: false
            add_index :users, :phone_number, unique: true
          end
        end
      end
    RUBY
  end

  def sms_migration_content
    <<~RUBY
      class ConvertToSmsAuth < ActiveRecord::Migration[8.0]
        def up
          # Clear all users as requested
          User.destroy_all
      #{'    '}
          # Remove email fields if they exist
          if column_exists?(:users, :email_address)
            remove_index :users, :email_address if index_exists?(:users, :email_address)
            remove_column :users, :email_address
          end
      #{'    '}
          if column_exists?(:users, :password_digest)
            remove_column :users, :password_digest
          end
      #{'    '}
          # Add SMS field if it doesn't exist
          unless column_exists?(:users, :phone_number)
            add_column :users, :phone_number, :string, null: false
            add_index :users, :phone_number, unique: true
          end
        end

        def down
          # Clear all users
          User.destroy_all
      #{'    '}
          # Remove SMS field
          if column_exists?(:users, :phone_number)
            remove_index :users, :phone_number if index_exists?(:users, :phone_number)
            remove_column :users, :phone_number
          end
      #{'    '}
          # Add email fields
          unless column_exists?(:users, :email_address)
            add_column :users, :email_address, :string, null: false
            add_index :users, :email_address, unique: true
          end
      #{'    '}
          unless column_exists?(:users, :password_digest)
            add_column :users, :password_digest, :string, null: false
          end
        end
      end
    RUBY
  end

  def display_completion_message
    say_status_with_color "completed", "Authentication switched to #{auth_method}", :green
    say ""
    say "Next steps:", :yellow
    say "  1. Restart your Rails server for configuration changes to take effect", :white
    say "  2. Visit your application to test the new authentication method", :white

    if auth_method == "sms"
      say "  3. For SMS testing, use verification codes: 1234 or 0000", :white
    end

    say ""
  end

  def say_status_with_color(status, message, color = :green)
    say "#{status.ljust(12)} #{message}", color
  end
end

class EnvVarGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  desc "Add a new environment variable to all proper places (.env, deploy.yml, secrets, 1Password)"

  argument :variable_name, type: :string, desc: "Environment variable name (UPPER_CASE)"
  argument :variable_value, type: :string, desc: "Environment variable value", default: "CHANGEME"

  class_option :description, type: :string, desc: "Description of the environment variable"

  def add_environment_variable
    @variable_name = variable_name.upcase
    @variable_value = variable_value
    @description = options[:description]

    say_status_with_color "adding", "Environment variable: #{@variable_name}", :blue
    say "=" * 80, :blue

    # Phase 1: Validate inputs
    validate_inputs

    # Phase 2: Add to .env file
    add_to_env_file

    # Phase 3: Update Kamal deployment configuration
    update_deploy_config

    # Phase 4: Update Kamal secrets
    update_kamal_secrets

    # Phase 5: Update 1Password vault
    update_onepassword_vault

    say_status_with_color "completed", "Environment variable #{@variable_name} added successfully!", :green
    display_next_steps
  end

  private

  def validate_inputs
    say_status_with_color "phase", "1/5 - Validating inputs", :cyan

    # Check if variable name is valid
    unless @variable_name.match?(/\A[A-Z][A-Z0-9_]*\z/)
      say_status_with_color "error", "Variable name must be UPPER_CASE with underscores", :red
      exit 1
    end


    # Check if required files exist
    unless File.exist?(".env")
      say_status_with_color "error", ".env file not found", :red
      exit 1
    end

    unless File.exist?("config/deploy.yml")
      say_status_with_color "error", "config/deploy.yml not found. Run 'rails generate mesh' first.", :red
      exit 1
    end

    unless File.exist?(".kamal/secrets")
      say_status_with_color "error", ".kamal/secrets not found. Run 'rails generate mesh' first.", :red
      exit 1
    end

    say_status_with_color "completed", "Input validation passed", :green
    say ""
  end

  def add_to_env_file
    say_status_with_color "phase", "2/5 - Adding to .env file", :cyan

    env_content = File.read(".env")

    # Check if variable already exists
    if env_content.include?("#{@variable_name}=")
      say_status_with_color "skipped", "#{@variable_name} already exists in .env", :yellow
      return
    end

    # Add the variable with optional description
    new_entry = ""
    new_entry += "\n# #{@description}\n" if @description
    new_entry += "#{@variable_name}=#{@variable_value}\n"

    File.write(".env", env_content + new_entry)
    say_status_with_color "added", "#{@variable_name} to .env file", :green
    say ""
  end

  def update_deploy_config
    say_status_with_color "phase", "3/5 - Updating Kamal deployment configuration", :cyan

    deploy_content = File.read("config/deploy.yml")

    # Add to secret section
    if deploy_content.include?("    - #{@variable_name}")
      say_status_with_color "skipped", "#{@variable_name} already in deploy.yml secrets", :yellow
    else
      # Find the secret section and add the variable
      updated_content = deploy_content.gsub(
        /(env:\s*\n\s*secret:\s*\n(?:\s*-\s*[A-Z_]+\s*\n)*)/m
      ) do |match|
        match.chomp + "    - #{@variable_name}\n"
      end

      # Also add to builder secrets section
      updated_content = updated_content.gsub(
        /(builder:\s*\n.*?secrets:\s*\n(?:\s*-\s*[A-Z_]+\s*\n)*)/m
      ) do |match|
        match.chomp + "    - #{@variable_name}\n"
      end

      File.write("config/deploy.yml", updated_content)
      say_status_with_color "added", "#{@variable_name} to deploy.yml secrets section", :green
    end
    say ""
  end

  def update_kamal_secrets
    say_status_with_color "phase", "4/5 - Updating Kamal secrets", :cyan

    secrets_content = File.read(".kamal/secrets")

    # Check if variable already exists
    if secrets_content.include?(@variable_name)
      say_status_with_color "skipped", "#{@variable_name} already in .kamal/secrets", :yellow
      return
    end

    # Add to the fetch command
    updated_content = secrets_content.gsub(
      /(SECRETS=\$\(kamal secrets fetch[^)]+)(\))/
    ) do |match|
      match.gsub(")", " #{@variable_name})")
    end

    # Add extraction line
    extraction_line = "#{@variable_name}=$(kamal secrets extract #{@variable_name} ${SECRETS})"
    updated_content += "\n#{extraction_line}"

    File.write(".kamal/secrets", updated_content)
    say_status_with_color "added", "#{@variable_name} to .kamal/secrets", :green
    say ""
  end

  def update_onepassword_vault
    say_status_with_color "phase", "5/5 - Updating 1Password vault", :cyan

    # Check if 1Password CLI is available
    unless onepassword_cli_available?
      say_status_with_color "warning", "1Password CLI not available. Manual update required.", :yellow
      say "Please manually add #{@variable_name} to your 1Password vault", :yellow
      return
    end

    # Extract app name from current secrets file
    secrets_content = File.read(".kamal/secrets")
    app_name_match = secrets_content.match(/--from Personal\/([^\s]+)/)

    unless app_name_match
      say_status_with_color "error", "Could not determine app name from .kamal/secrets", :red
      return
    end

    app_name = app_name_match[1]

    # Add the field to 1Password
    add_cmd = [
      "op", "item", "edit", app_name,
      "--vault=Personal",
      "#{@variable_name}[password]=#{@variable_value}"
    ]

    if system(*add_cmd, out: File::NULL, err: File::NULL)
      say_status_with_color "added", "#{@variable_name} to 1Password vault: Personal/#{app_name}", :green
    else
      say_status_with_color "warning", "Could not update 1Password vault automatically", :yellow
      say "Please manually add #{@variable_name} to Personal/#{app_name}", :yellow
    end
    say ""
  end

  def onepassword_cli_available?
    system("op --version > /dev/null 2>&1") && system("op account list > /dev/null 2>&1")
  end

  def say_status_with_color(status, message, color = :green)
    say "#{status.ljust(12)} #{message}", color
  end

  def display_next_steps
    say "=" * 80, :green
    say "🎉 ENVIRONMENT VARIABLE ADDED! 🎉", :green
    say "=" * 80, :green
    say ""
    say "Variable added: #{@variable_name}", :yellow
    say "Type: Secret", :yellow
    say "Value: #{@variable_value}", :yellow
    say ""
    say "Files updated:", :yellow
    say "  • .env", :white
    say "  • config/deploy.yml", :white
    say "  • .kamal/secrets", :white
    say "  • 1Password vault (if CLI available)", :white
    say ""
    say "Next steps:", :yellow
    say "  1. Verify the secret was added to your 1Password vault", :white
    say "  2. Update the value in 1Password if needed", :white
    say "  3. Deploy with 'kamal deploy' to use the new variable", :white
    say ""
  end
end

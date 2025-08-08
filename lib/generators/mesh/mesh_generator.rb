class MeshGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  desc "Rename Rails application and setup Kamal deployment with 1Password integration"

  argument :new_name, type: :string, desc: "New application name (snake_case)"

  class_option :verbose, type: :boolean, default: false, desc: "Enable verbose logging"

  def setup_mesh
    @old_name = "keystone_base"

    say_status_with_color "starting", "Setting up Mesh: renaming '#{@old_name}' to '#{new_name}' and configuring deployment", :blue
    say "=" * 80, :blue

    # Phase 1: Rename Application
    rename_application

    # Phase 2: Check Prerequisites
    check_prerequisites

    # Phase 3: Seed Environment Variables from Keystone Base
    seed_environment_variables_from_keystone_base

    # Phase 4: Gather Deployment Configuration
    @deployment_config = gather_deployment_config

    # Phase 5: Read Environment and Secrets
    @env_vars = parse_env_file
    @rails_master_key = read_master_key
    @github_token = read_github_token_from_vault(@deployment_config[:onepassword_account])

    # Phase 6: Update URL Options Configuration
    update_url_options_configuration

    # Phase 7: Generate Kamal Configuration
    generate_kamal_config

    # Phase 8: Setup 1Password Integration
    setup_onepassword_integration

    say_status_with_color "completed", "Mesh setup complete!", :green
    display_next_steps
  end

  private

  # ============================================================================
  # PHASE 1: APPLICATION RENAMING (from setup generator)
  # ============================================================================

  def rename_application
    # Generate different naming conventions
    old_pascal = @old_name.camelize
    new_pascal = new_name.camelize
    old_kebab = @old_name.dasherize
    new_kebab = new_name.dasherize
    old_title = @old_name.humanize.titleize
    new_title = new_name.humanize.titleize

    say "Transformations:", :yellow
    say "  Snake case: #{@old_name} → #{new_name}"
    say "  Pascal case: #{old_pascal} → #{new_pascal}"
    say "  Kebab case: #{old_kebab} → #{new_kebab}"
    say "  Title case: #{old_title} → #{new_title}"
    say ""

    # Update config/application.rb
    update_application_config(old_pascal, new_pascal)

    # Update config/deploy.yml (if it exists)
    update_deploy_config(@old_name, new_name)

    # Update PWA manifest
    update_pwa_manifest(old_pascal, new_pascal, old_title, new_title)

    # Update Dockerfile
    update_dockerfile(@old_name, new_name, old_kebab, new_kebab)

    # Update application layout title
    update_application_layout_title(old_title, new_title)

    say_status_with_color "completed", "Application renamed from '#{@old_name}' to '#{new_name}'", :green
    say ""
  end

  def update_application_config(old_pascal, new_pascal)
    config_file = "config/application.rb"
    return unless File.exist?(config_file)

    say "Updating #{config_file}...", :blue

    content = File.read(config_file)
    updated_content = content.gsub("module #{old_pascal}", "module #{new_pascal}")

    File.write(config_file, updated_content)
    say "  ✓ Module name updated: #{old_pascal} → #{new_pascal}", :green
  end

  def update_deploy_config(old_name, new_name)
    deploy_file = "config/deploy.yml"
    return unless File.exist?(deploy_file)

    say "Updating existing #{deploy_file}...", :blue

    content = File.read(deploy_file)

    # Update service name
    content = content.gsub(/^service:\s*#{old_name}/, "service: #{new_name}")

    # Update image name
    content = content.gsub(/image:\s*your-user\/#{old_name}/, "image: your-user/#{new_name}")

    # Update volume name
    content = content.gsub(/#{old_name}_storage/, "#{new_name}_storage")

    # Update database host reference in comments
    content = content.gsub(/#{old_name}-db/, "#{new_name}-db")

    File.write(deploy_file, content)
    say "  ✓ Service name, image name, and volume name updated", :green
  end

  def update_pwa_manifest(old_pascal, new_pascal, old_title, new_title)
    manifest_file = "app/views/pwa/manifest.json.erb"
    return unless File.exist?(manifest_file)

    say "Updating #{manifest_file}...", :blue

    content = File.read(manifest_file)

    # Update app name
    content = content.gsub(/"name":\s*"#{old_pascal}"/, "\"name\": \"#{new_pascal}\"")

    # Update description
    content = content.gsub(/"description":\s*"#{old_pascal}\.?"/, "\"description\": \"#{new_pascal}.\"")

    File.write(manifest_file, content)
    say "  ✓ PWA manifest name and description updated", :green
  end

  def update_dockerfile(old_name, new_name, old_kebab, new_kebab)
    dockerfile = "Dockerfile"
    return unless File.exist?(dockerfile)

    say "Updating #{dockerfile}...", :blue

    content = File.read(dockerfile)

    # Update docker build comment
    content = content.gsub(/# docker build -t #{old_name}/, "# docker build -t #{new_name}")

    # Update docker run comment
    content = content.gsub(/--name #{old_name} #{old_name}/, "--name #{new_name} #{new_name}")

    File.write(dockerfile, content)
    say "  ✓ Dockerfile comments updated", :green
  end

  def update_application_layout_title(old_title, new_title)
    layout_file = "app/views/layouts/application.html.erb"
    return unless File.exist?(layout_file)

    say "Updating #{layout_file}...", :blue

    content = File.read(layout_file)

    # Update the default title in the title tag - escape the old_title for regex
    escaped_old_title = Regexp.escape(old_title)
    content = content.gsub(/content_for\(:title\) \|\| "#{escaped_old_title}"/, "content_for(:title) || \"#{new_title}\"")

    File.write(layout_file, content)
    say "  ✓ Application layout title updated: #{old_title} → #{new_title}", :green
  end

  # ============================================================================
  # PHASE 2: PREREQUISITES CHECK (from standalone_deployment generator)
  # ============================================================================

  def check_prerequisites
    unless File.exist?("config/routes.rb")
      say_status_with_color "error", "This doesn't appear to be a Rails application", :red
      exit 1
    end

    # Check for 1Password CLI
    unless onepassword_cli_available?
      say_status_with_color "error", "1Password CLI (op) not found or not authenticated", :red
      say "Please install and authenticate 1Password CLI:", :yellow
      say "  brew install 1password-cli", :white
      say "  op account add", :white
      say "  op signin", :white
      exit 1
    end

    say_status_with_color "completed", "Prerequisites check passed", :green
    say ""
  end

  # ============================================================================
  # PHASE 3: SEED ENVIRONMENT VARIABLES FROM KEYSTONE BASE
  # ============================================================================

  def seed_environment_variables_from_keystone_base
    say "Fetching environment variables from Personal/keystone_base...", :blue

    # Get all fields from the keystone_base 1Password item
    keystone_vars = fetch_all_secrets_from_vault("keystone_base")

    if keystone_vars.empty?
      say_status_with_color "warning", "No environment variables found in Personal/keystone_base", :yellow
      say "Continuing with local .env file only", :yellow

      # In verbose mode, show why it failed
      if options[:verbose]
        say "Debug: Testing 1Password CLI access...", :yellow
        test_onepassword_access
      end
    else
      # Write the seeded variables to .env file
      env_content = ""
      env_content += "# Environment variables seeded from Personal/keystone_base\n"
      env_content += "# Generated on #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}\n\n"

      keystone_vars.each do |key, value|
        env_content += "#{key}=#{value}\n"
      end

      File.write(".env", env_content)
      say_status_with_color "seeded", "#{keystone_vars.keys.size} environment variables from keystone base", :green

      if options[:verbose]
        say "Debug: Seeded variables: #{keystone_vars.keys.join(', ')}", :cyan
      end
    end

    say ""
  end

  # ============================================================================
  # PHASE 4: DEPLOYMENT CONFIGURATION (from standalone_deployment generator)
  # ============================================================================

  def gather_deployment_config
    config = {}
    config[:github_username] = ask("GitHub username:", default: "adenta")
    config[:domain] = ask("Domain name (e.g., myapp.com):")
    config[:server_ip] = ask("Server IP address:", default: "178.156.134.191")
    config[:onepassword_account] = ask("1Password account ID:", default: "ABOVBJHUF5G2PASRYQTVCYIJKM")

    say_status_with_color "completed", "Deployment configuration gathered", :green
    say ""
    config
  end

  # ============================================================================
  # PHASE 5: ENVIRONMENT & SECRETS (from standalone_deployment generator)
  # ============================================================================

  def parse_env_file
    return {} unless File.exist?(".env")

    env_vars = {}
    File.readlines(".env").each do |line|
      next if line.strip.empty? || line.start_with?("#")
      key, value = line.strip.split("=", 2)
      env_vars[key] = value if key && value
    end

    say_status_with_color "found", "#{env_vars.keys.size} environment variables", :green
    env_vars
  end

  def read_master_key
    if File.exist?("config/master.key")
      key = File.read("config/master.key").strip
      say_status_with_color "found", "Rails master key", :green
      key
    else
      say_status_with_color "warning", "config/master.key not found locally", :yellow
      say "Attempting to retrieve RAILS_MASTER_KEY from Personal/keystone_base...", :blue

      # Try to get the master key from keystone_base vault
      master_key_from_vault = fetch_secret_from_vault("RAILS_MASTER_KEY", "keystone_base", nil)

      if master_key_from_vault && !master_key_from_vault.empty?
        # Write the master key to the local file
        File.write("config/master.key", master_key_from_vault)
        say_status_with_color "retrieved", "Rails master key from keystone_base vault and saved locally", :green
        master_key_from_vault
      else
        say_status_with_color "error", "RAILS_MASTER_KEY not found in keystone_base vault either", :red
        say "Please ensure RAILS_MASTER_KEY exists in Personal/keystone_base or create config/master.key", :yellow
        exit 1
      end
    end
  end

  def read_github_token_from_vault(account_id)
    say "Reading GitHub token from 1Password...", :blue

    # Try to read from existing vault item
    token = fetch_secret_from_vault("KAMAL_REGISTRY_PASSWORD", "Rails-App-Template-Production", account_id)

    if token && token != "CHANGEME"
      say_status_with_color "found", "GitHub token in 1Password", :green
      token
    else
      say_status_with_color "error", "GitHub token not found in 1Password vault", :red
      say "Please add KAMAL_REGISTRY_PASSWORD to your 1Password vault at:", :yellow
      say "  Personal/Rails-App-Template-Production", :white
      exit 1
    end
  end

  # ============================================================================
  # PHASE 6: URL OPTIONS CONFIGURATION
  # ============================================================================

  def update_url_options_configuration
    say_status_with_color "phase", "6/8 - Updating URL options configuration", :cyan

    # Remove hard-coded mailer host from production.rb
    remove_hardcoded_mailer_host

    # Update the default_url_options_mailer.rb initializer with the actual domain
    update_url_options_initializer

    say_status_with_color "completed", "URL options updated to use domain: #{@deployment_config[:domain]}", :green
    say ""
  end

  def remove_hardcoded_mailer_host
    production_file = "config/environments/production.rb"
    return unless File.exist?(production_file)

    say "Removing hard-coded mailer host from #{production_file}...", :blue

    content = File.read(production_file)

    # Remove the hard-coded default_url_options line
    content = content.gsub(/^\s*config\.action_mailer\.default_url_options\s*=\s*\{[^}]*\}\s*\n/, "")

    File.write(production_file, content)
    say "  ✓ Hard-coded mailer host removed", :green
  end

  def update_url_options_initializer
    initializer_file = "config/initializers/default_url_options_mailer.rb"
    return unless File.exist?(initializer_file)

    say "Updating #{initializer_file}...", :blue

    domain = @deployment_config[:domain]

    # Create the new initializer content with the actual domain
    new_content = <<~RUBY
      # Default URL options for different environments
      hosts = {
        development: 'localhost:3000',
        test: 'test.example.com',
        production: '#{domain}'
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
    RUBY

    File.write(initializer_file, new_content)
    say "  ✓ URL options initializer updated with domain: #{domain}", :green
  end

  # ============================================================================
  # PHASE 7: KAMAL CONFIGURATION (from standalone_deployment generator)
  # ============================================================================

  def generate_kamal_config
    say_status_with_color "phase", "7/8 - Generating Kamal configuration", :cyan

    # Determine which features are enabled based on env vars
    features = {
      setup_email: @env_vars.key?("SMTP_EMAIL_ADDRESS"),
      authentication_type: @env_vars.key?("TWILIO_ACCOUNT_SID") ? "sms" : "email"
    }

    # Generate deploy.yml with NEW app name
    template_vars = @deployment_config.merge(features).merge(app_name: new_name)
    deploy_content = render_template("kamal/deploy.yml.tt", template_vars)
    File.write("config/deploy.yml", deploy_content)

    # Generate .kamal/secrets
    FileUtils.mkdir_p(".kamal")
    secrets_content = render_template("kamal/secrets.tt", template_vars)
    File.write(".kamal/secrets", secrets_content)

    say_status_with_color "created", "config/deploy.yml (with app name: #{new_name})", :green
    say_status_with_color "created", ".kamal/secrets", :green
    say ""
  end

  # ============================================================================
  # PHASE 8: 1PASSWORD INTEGRATION (from standalone_deployment generator)
  # ============================================================================

  def setup_onepassword_integration
    say_status_with_color "phase", "8/8 - Setting up 1Password integration", :cyan

    # Prepare all secrets for the vault using NEW app name
    all_secrets = @env_vars.merge({
      "RAILS_MASTER_KEY" => @rails_master_key,
      "KAMAL_REGISTRY_PASSWORD" => @github_token
    })

    create_production_vault(all_secrets, @deployment_config[:onepassword_account])
    say ""
  end

  def create_production_vault(secrets, account_id)
    # Use NEW app name for the vault item
    item_title = new_name

    say_status_with_color "creating", "1Password item: Personal/#{item_title}", :cyan

    # Build item fields
    item_fields = []
    secrets.each do |key, value|
      item_fields << "#{key}[password]=#{value}"
    end

    # Create the production item
    create_cmd = [
      "op", "item", "create",
      "--category=password",
      "--vault=Personal",
      "--title=#{item_title}"
    ] + item_fields

    if system(*create_cmd, out: File::NULL, err: File::NULL)
      say_status_with_color "created", "Personal/#{item_title}", :green
    else
      say_status_with_color "failed", "Could not create 1Password item", :red
      say "You may need to manually create the item or check your 1Password CLI authentication", :yellow
    end
  end

  # ============================================================================
  # HELPER METHODS
  # ============================================================================

  def render_template(template_path, variables = {})
    template_file = File.join(self.class.source_root, template_path)
    template = ERB.new(File.read(template_file))

    # Create a binding with the variables
    binding_context = binding
    variables.each do |key, value|
      binding_context.local_variable_set(key, value)
    end

    template.result(binding_context)
  end

  def fetch_secret_from_vault(secret_key, vault_item, account_id)
    value = `op item get "#{vault_item}" --vault "Personal" --fields "#{secret_key}" --reveal 2>/dev/null`.strip

    if value.empty? || value.include?("use 'op item get") || value.include?("[ERROR]")
      nil
    else
      value
    end
  end

  def fetch_all_secrets_from_vault(vault_item)
    cmd = "op item get \"#{vault_item}\" --vault \"Personal\" --format json"

    if options[:verbose]
      say "Debug: Executing command: #{cmd}", :cyan
    end

    # Get the item in JSON format to extract all fields
    json_output = `#{cmd} 2>&1`.strip

    if options[:verbose]
      say "Debug: Command output length: #{json_output.length} characters", :cyan
      if json_output.length < 500
        say "Debug: Raw output: #{json_output}", :cyan
      else
        say "Debug: Output too long to display (truncated): #{json_output[0..200]}...", :cyan
      end
    end

    if json_output.empty?
      if options[:verbose]
        say "Debug: Empty output from 1Password CLI", :red
      end
      return {}
    end

    if json_output.include?("[ERROR]") || json_output.include?("ERROR")
      if options[:verbose]
        say "Debug: Error in 1Password CLI output: #{json_output}", :red
      end
      return {}
    end

    begin
      item_data = JSON.parse(json_output)
      secrets = {}

      if options[:verbose]
        say "Debug: Successfully parsed JSON, found #{item_data['fields']&.length || 0} fields", :cyan
      end

      # Extract password fields (which contain our environment variables)
      item_data["fields"]&.each do |field|
        if options[:verbose]
          say "Debug: Field - type: #{field['type']}, label: #{field['label']}, has_value: #{!field['value'].nil?}", :cyan
        end

        if field["type"] == "CONCEALED" && field["label"] && field["value"]
          secrets[field["label"]] = field["value"]
        end
      end

      if options[:verbose]
        say "Debug: Extracted #{secrets.keys.size} secrets: #{secrets.keys.join(', ')}", :cyan
      end

      secrets
    rescue JSON::ParserError => e
      if options[:verbose]
        say "Debug: JSON parsing failed: #{e.message}", :red
        say "Debug: Attempted to parse: #{json_output[0..200]}...", :red
      end
      {}
    end
  end

  def test_onepassword_access
    say "Debug: Testing basic 1Password CLI functionality...", :cyan

    # Test 1: Check if op command exists
    if system("which op > /dev/null 2>&1")
      say "Debug: ✓ 1Password CLI found", :green
    else
      say "Debug: ✗ 1Password CLI not found in PATH", :red
      return
    end

    # Test 2: Check if authenticated
    accounts_output = `op account list 2>&1`.strip
    if $?.success?
      say "Debug: ✓ 1Password CLI authenticated", :green
      say "Debug: Available accounts: #{accounts_output.split("\n").length} accounts", :cyan
    else
      say "Debug: ✗ 1Password CLI not authenticated", :red
      say "Debug: Account list output: #{accounts_output}", :red
      return
    end

    # Test 3: Check if Personal vault is accessible
    vaults_output = `op vault list --format json 2>&1`.strip
    if $?.success?
      begin
        vaults = JSON.parse(vaults_output)
        personal_vault = vaults.find { |v| v["name"] == "Personal" }
        if personal_vault
          say "Debug: ✓ Personal vault found (ID: #{personal_vault['id']})", :green
        else
          say "Debug: ✗ Personal vault not found", :red
          say "Debug: Available vaults: #{vaults.map { |v| v['name'] }.join(', ')}", :cyan
        end
      rescue JSON::ParserError
        say "Debug: ✗ Could not parse vault list JSON", :red
      end
    else
      say "Debug: ✗ Could not list vaults", :red
      say "Debug: Vault list output: #{vaults_output}", :red
    end

    # Test 4: Check if keystone_base item exists
    item_output = `op item get "keystone_base" --vault "Personal" --format json 2>&1`.strip
    if $?.success?
      say "Debug: ✓ keystone_base item found in Personal vault", :green
      begin
        item_data = JSON.parse(item_output)
        field_count = item_data["fields"]&.length || 0
        concealed_fields = item_data["fields"]&.select { |f| f["type"] == "CONCEALED" }&.length || 0
        say "Debug: Item has #{field_count} total fields, #{concealed_fields} concealed fields", :cyan
      rescue JSON::ParserError
        say "Debug: Could not parse item JSON", :red
      end
    else
      say "Debug: ✗ keystone_base item not found or not accessible", :red
      say "Debug: Item get output: #{item_output}", :red
    end
  end

  def onepassword_cli_available?
    system("op --version > /dev/null 2>&1") && system("op account list > /dev/null 2>&1")
  end

  def say_status_with_color(status, message, color = :green)
    say "#{status.ljust(12)} #{message}", color
  end

  def display_next_steps
    say "=" * 80, :green
    say "🎉 MESH SETUP COMPLETE! 🎉", :green
    say "=" * 80, :green
    say ""
    say "Your application has been transformed:", :yellow
    say "  • Renamed from 'keystone_base' to '#{new_name}'", :white
    say "  • URL options updated to use domain: #{@deployment_config[:domain]}", :white
    say "  • Kamal deployment configured", :white
    say "  • All secrets stored in 1Password: Personal/#{new_name}", :white
    say ""
    say "Next steps:", :yellow
    say "  1. Verify your secrets in 1Password vault: #{@deployment_config[:onepassword_account]}/#{new_name}", :white
    say "  2. Run 'kamal setup' to prepare your server", :white
    say "  3. Run 'kamal deploy' to deploy your application", :white
    say "  4. Configure your DNS to point #{@deployment_config[:domain]} to #{@deployment_config[:server_ip]}", :white
    say ""
  end
end

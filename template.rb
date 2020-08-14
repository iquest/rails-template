# frozen_string_literal: true

require "fileutils"
require "shellwords"

# required gems
begin
  require 'byebug'
rescue LoadError
  require 'bundler/inline'

  gemfile do
    source 'https://rubygems.org'
    gem "byebug"
  end
end

REPO = "iquest/rails-template"

# Copied from: https://github.com/mattbrictson/rails-template
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("rails-template-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      "--quiet",
      "https://github.com/#{REPO}.git",
      tempdir
    ].map(&:shellescape).join(" ")

    if (branch = __FILE__[%r{rails-template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def rails_version
  @rails_version ||= Gem::Version.new(Rails::VERSION::STRING)
end

def rails_6?
  Gem::Requirement.new(">= 6.0.0.beta1", "< 7").satisfied_by? rails_version
end

def set_application_name
  # Add Application Name to Config
  application "config.application_name = Rails.application.class.module_parent_name"
end

def add_base_gems
  gem 'mini_magick', '~> 4.10', '>= 4.10.1'
  gem 'sidekiq', '~> 6.0', '>= 6.0.3'
  gem 'image_processing'
  gem 'default_value_for'
  gem "puma-heroku", group: :production
  gem "oj"
  gem "pagy"
  gem "rails-i18n"
  gem "dry-core"
  gem "dry-types"

  gem_group :development do
    gem 'pry-rails'
    gem 'letter_opener'
    gem 'foreman'
  end

  gem_group :development, :test do
    gem 'factory_bot_rails'
    gem "dotenv-rails"
  end

  gem_group :test do
    gem 'capybara'
    gem 'database_cleaner'
    gem 'launchy'
    gem 'selenium-webdriver'
  end

  copy_file '.env.development'
  append_to_file ".env.development" do
    "DATABASE_URL=postgresql:///#{app_name}_development"
  end
end

def add_pagy
  gem "pagy"
  inject_into_class "app/controllers/application_controller.rb", 'ApplicationController' do
    'include Pagy::Backend'
  end
  insert_into_file "app/controllers/application_controller.rb", after: /module ApplicationHelper/ do
    'include Pagy::Frontend'
  end
end

def default_config
  application do
    'config.i18n.available_locales = [:en, :cs]
    config.i18n.default_locale = :cs
    config.i18n.fallbacks = true
    config.i18n.fallbacks = [:en]
    config.time_zone = "Prague"'
  end
end

def add_sentry
  gem "sentry-raven"
end

def add_rubocop
  gem_group :development do
    gem "rubocop"
    gem "relaxed-rubocop"
  end

  copy_file ".rubocop.yml"
end

def add_devise
  gem 'devise', '~> 4.7', '>= 4.7.2'
  gem "devise-i18n"

  after_bundle do
    # Install Devise
    generate "devise:install"
    generate "devise:controller auth"
    generate "devise:views auth"

    # Configure Devise
    environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
                env: 'development'

    # Create Devise User
    generate :devise, "User",
            "name",
            "role:integer"

    inject_into_class "app/models/user.rb", "User" do
      "  enum :role { basic: 0, admin: 1 }"
      "  default_value_for :role, :basic"
    end

    gsub_file "config/initializers/devise.rb",
              /  # config.secret_key = .+/,
              "  config.secret_key = Rails.application.credentials.secret_key_base"
  end
end

def add_home_conntroller
  generate :controller, "Home", "index"
end

def add_javascript
  run "yarn add expose-loader jquery popper.js bootstrap data-confirm-modal local-time"

  content = <<~JS
    const webpack = require('webpack')
    environment.plugins.append('Provide', new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      Rails: '@rails/ujs'
    }))
  JS

  inject_into_file 'config/webpack/environment.js', content + "\n", before: "module.exports = environment"
end

def remove_sprockets
  comment_lines "Gemfile", /sprockets/
  comment_lines "config/application.rb", /sprockets/
end

def copy_templates
  remove_dir "app/assets"

  copy_file "Procfile"
  copy_file "Procfile.dev"

  directory "app", force: true
  directory "config", force: true
  directory "lib", force: true
end

def add_simple_form
  gem 'simple_form', '~> 4.1'
  after_bundle do
    generate 'simple_form:install', '--bootstrap'
  end
end

def add_foreman
  gem_group :development do
    gem "forman"
  end
  copy_file ".foreman"
end

def add_sidekiq
  environment "config.active_job.queue_adapter = :sidekiq"

  inject_into_file "config/routes.rb",
                   "require 'sidekiq/web'\n\n",
                   before: "Rails.application.routes.draw do"

  content = <<-RUBY
    authenticate :user, lambda { |u| u.role?(:admin) } do
      mount Sidekiq::Web => '/sidekiq'
    end
  RUBY
  insert_into_file "config/routes.rb", "#{content}\n\n", after: "Rails.application.routes.draw do\n"
end

def add_seeds
  copy_file "db/seeds.rb", force: true
  directory "db/seeds"
end

def stop_spring
  run "spring stop"
  comment_lines "Gemfile", /spring/
end

def add_sitemap
  gem 'sitemap_generator', '~> 6.1', '>= 6.1.2'
  after_bundle do
    rails_command "sitemap:install"
  end
end

def add_draper
  gem 'draper'
  after_bundle do
    generate 'draper:install'
  end
end

def add_gitignore
  append_to_file '.gitignore', <<-GITIGNORE
    .env.*.local
    .env.local
    .env.production

    .byebug_history
    .idea
    .vscode
    .rakeTasks
    .pry_history
    .generators
  GITIGNORE
end

def add_admin
  after_bundle do
    run "yarn add admin-lte@^3.0.0-beta.1 daterangepicker@^3.0.5 moment-timezone tempusdominus-core"
  end

  route <<-ROUTE
    namespace :admin do
      resource :dashboard, only: [:show]
    end
  ROUTE
end

def add_bullet
  gem_group :development do
    gem 'bullet'
  end

  after_bundle do
    initializer 'bullet.rb', <<-CODE
      # frozen_string_literal: true

      if Rails.env.development?
        Bullet.enable = true
        Bullet.console = true
        Bullet.rails_logger = true
        Bullet.add_footer = true
        Bullet.skip_html_injection = false
      end
    CODE
  end
end

def add_letter_opener
  gem_group :development do
    gem 'letter_opener'
  end

  environment 'config.action_mailer.delivery_method = :letter_opener', env: 'development'
end

# Main setup
add_template_repository_to_source_path

add_base_gems

after_bundle do
  set_application_name
  stop_spring
  add_draper
  add_simple_form
  add_pagy
  add_rubocop
  add_letter_opener
  add_bullet
  add_devise if yes?("Devise?")
  add_javascript
  add_sidekiq if yes?("Sidekiq?")
  copy_templates
  add_sitemap if yes?("Sitemap?")
  add_gitignore
  add_admin
  add_seeds

  # Migrate
  rails_command "db:create"
  rails_command "active_storage:install"
  rails_command "db:migrate"

  # Commit everything to git

  git :init
  git add: "."
  git commit: %{ -m 'Initial commit' }

  say
  say "App successfully created!", :blue
  say
  say "To get started with your new app:", :green
  say "cd #{app_name} - Switch to your new app's directory."
  say "foreman start - Run Rails, sidekiq, and webpack-dev-server."
end

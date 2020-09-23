# frozen_string_literal: true

require "fileutils"
require "shellwords"

begin
  require 'byebug' # template debugging
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
  gem 'image_processing'
  gem 'default_value_for'
  gem "oj"
  gem "pagy"
  gem 'rails-i18n', '~> 6.0.0'
  gem "dry-core"
  gem "dry-types", '~> 1.2'
  gem "dry-struct"
  gem "puma-heroku"
  gem 'heroku-deflater', group: :production
  gem "sentry-raven"

  gem_group :development do
    gem 'pry-rails'
    gem 'letter_opener'
    gem 'foreman', require: false
    gem 'overcommit', require: false
    gem 'magic_frozen_string_literal', require: false
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
  after_bundle do
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

def add_rubocop
  gem_group :development do
    gem "rubocop"
    gem "relaxed-rubocop"
  end

  copy_file ".rubocop.yml"
end

def add_user
  gem 'devise', '~> 4.7', '>= 4.7.2'
  gem "devise-i18n"
  gem "action_policy"

  after_bundle do
    # Install Devise
    generate "devise:install"
    generate "devise:i18n:views", "auth"
    # Install Action Policy
    generate "action_policy:install"

    # Configure Devise
    environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
                env: 'development'

    # Create Devise User
    generate :devise, "User",
             "name",
             "role:integer"

    inject_into_class "app/models/user.rb", "User" do
      <<-CODE
      enum role: { basic: 0, admin: 1 }
      default_value_for :role, :basic
      CODE
    end

    inject_into_file "app/models/user.rb", before: /^end/ do
      <<-CODE
      def role?(role_name)
        self.role == role_name.to_s
      end
      CODE
    end

    gsub_file "config/routes.rb", /devise_for :users/ do
      <<-ROUTE
      devise_for :users, path: "auth"
      ROUTE
    end

    gsub_file "config/initializers/devise.rb",
              /  # config.secret_key = .+/,
              "  config.secret_key = Rails.application.credentials.secret_key_base"

    generate "action_policy:policy User"
  end
end

def add_home_conntroller
  generate :controller, "Home", "index"
end

def add_javascript
  run "yarn add expose-loader jquery popper.js bootstrap data-confirm-modal local-time"

  inject_into_file "app/javascript/packs/application.js" do
    <<-CODE
    const images = require.context('../images', true)
    const imagePath = (name) => images(name, true)

    import $ from 'jquery';
    import 'bootstrap';
    import '../stylesheets/application';

    document.addEventListener('turbolinks:load', () => {
        $('[data-toggle="tooltip"]').tooltip();
        $('[data-toggle="popover"]').popover({html: true, sanitize: false});
        $('.toast').toast({ autohide: false });
        $('#toast').toast('show');
    });
    CODE
  end
end

def remove_sprockets
  comment_lines "Gemfile", /sprockets/
  comment_lines "config/application.rb", /sprockets/
end

def copy_templates
  remove_dir "app/assets"

  copy_file "Procfile"
  copy_file "Procfile.dev"
  copy_file ".foreman"

  directory "app", force: true
  directory "config", force: true
  # directory "lib", force: true
end

def add_simple_form
  gem 'simple_form', '~> 4.1'
  after_bundle do
    generate 'simple_form:install', '--bootstrap'
  end
end

def add_sidekiq
  gem 'sidekiq', '~> 6.0', '>= 6.0.3'

  after_bundle do
    environment "config.active_job.queue_adapter = :sidekiq"

    inject_into_file "config/routes.rb",
                     "require 'sidekiq/web'\nSidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]\n\n",
                     before: "Rails.application.routes.draw do"

    content = <<-RUBY
      authenticate :user, lambda { |u| u.role?(:admin) } do
        mount Sidekiq::Web => '/sidekiq'
      end
    RUBY
    insert_into_file "config/routes.rb", "#{content}\n\n", after: "Rails.application.routes.draw do\n"

    procfile = "worker: bundle exec sidekiq -c ${SIDEKIQ_CONCURRENCY:-5}"
    append_to_file "Procfile" do
      procfile
    end

    append_to_file "Procfile.dev" do
      procfile
    end
  end
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
    generate 'draper:install', '-s'
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
    run "yarn add admin-lte@^3.0 daterangepicker@^3.0 moment-timezone tempusdominus-core"
  end

  route <<-ROUTE
    namespace :admin do
      root to: 'dashboard#index'
    end
  ROUTE
end

def add_bullet
  gem_group :development do
    gem 'bullet'
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

# after_bundle do
set_application_name
stop_spring
add_draper
add_simple_form
add_pagy
add_rubocop
add_letter_opener
add_bullet
add_user if yes?("Users?")
add_sidekiq if yes?("Sidekiq?")
copy_templates
add_sitemap if yes?("Sitemap?")
add_gitignore
add_javascript
add_admin
add_seeds

after_bundle do
  # Migrate
  rails_command "db:create"
  rails_command "active_storage:install"
  rails_command "db:migrate"

  # Commit everything to git

  git :init
  run "magic_frozen_string_literal ."
  run "rubocop --auto-correct"
  run "overcommit --install"
  git add: "."
  git commit: %{ -m 'Initial commit' }

  say
  say "App successfully created!", :blue
  say
  say "To get started with your new app:", :green
  say "cd #{app_name} - Switch to your new app's directory."
  say "foreman start - Run Rails, sidekiq, and webpack-dev-server."
end

# frozen_string_literal: true

if defined?(Bullet) && Rails.env.development?
  Bullet.enable = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true
  Bullet.skip_html_injection = false
end

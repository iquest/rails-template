# frozen_string_literal: true

module Err
  class << self
    def notify(exception, info = {})
      logger.error("#{exception.class} #{exception.message}\n#{filter_backtrace(exception).join("\n")}")
      Raven.capture_exception(exception, extra: info) if defined?(Raven)
    rescue StandardError => e
      warn "[err] Error reporting exception: #{e.class.name}: #{e.message}"
    end

    private

    def logger
      Rails.logger
    end

    # filter backtrace
    # takes all lines until fist application code line
    # and then only application code lines
    def filter_backtrace(exception)
      prefix = Rails.root.to_s
      select_prefix = false
      exception.backtrace.select do |line|
        if line.start_with?(prefix)
          select_prefix = true
        else
          !select_prefix
        end
      end
    end
  end
end

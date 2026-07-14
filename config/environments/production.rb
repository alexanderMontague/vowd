require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  config.assets.compile = false

  config.active_storage.service = :local

  config.force_ssl = true
  config.ssl_options = { redirect: { exclude: ->(req) { req.path == "/ping" } } }

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [:request_id]

  # In containers, write logs to STDOUT so `docker logs` (and the platform's log
  # collector) captures request logging instead of a file hidden inside the image.
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    $stdout.sync = true
    logger = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", nil), protocol: "https" }
  config.action_mailer.delivery_method = :smtp
  # SMTP transport is configured centrally in config/initializers/smtp.rb.

  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false

  # Custom domains are dynamic; TLS/proxy is handled outside the app.
  config.hosts.clear
end

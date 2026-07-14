require "active_support/core_ext/integer/time"

Rails.application.configure do
  # foreman/bin/dev pipes STDOUT, so Ruby buffers it and request logs never flush.
  # Autoflushing makes the server's request logging show up live in the terminal.
  $stdout.sync = true

  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  config.active_storage.service = :local

  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: "localhost", port: 3003 }
  config.action_mailer.delivery_method = :smtp
  # SMTP transport is configured centrally in config/initializers/smtp.rb.

  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  # Multi-tenant hosts: apex + subdomains of APP_BASE_DOMAIN (e.g. vowd.localhost).
  base = ENV.fetch("APP_BASE_DOMAIN", "vowd.localhost").to_s.split(":").first
  config.hosts << base
  config.hosts << ".#{base}"
  config.hosts << "localhost"
  config.hosts << /.*\.localhost/
end

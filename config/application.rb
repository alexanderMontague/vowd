require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Vowd
  class Application < Rails::Application
    config.load_defaults 7.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "UTC"

    config.active_job.queue_adapter = :async

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
      g.helper false
      g.assets false
    end
  end
end

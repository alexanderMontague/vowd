# Share the session cookie across wedding subdomains of APP_BASE_DOMAIN
# (e.g. vowd.localhost ↔ slug.vowd.localhost). Custom domains still require
# a separate login on that host.
base = ENV.fetch("APP_BASE_DOMAIN", "").to_s.strip.downcase.split(":").first
cookie_domain = if base.present? && !%w[localhost 127.0.0.1].include?(base)
                  ".#{base}"
                end

Rails.application.config.session_store :cookie_store,
                                       key: "_vowd_session",
                                       domain: cookie_domain

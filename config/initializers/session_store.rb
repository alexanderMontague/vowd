# Session cookies must be host-aware: shared across APP_BASE_DOMAIN subdomains
# for admin/platform flows, host-only on wedding custom domains so guest CSRF
# works. Domain is applied per-request in ApplicationController.
Rails.application.config.session_store :cookie_store, key: "_vowd_session"

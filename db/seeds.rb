# Demo wedding for local development and marketing imagery.
# Login: demo@vowd.test / password  (on the wedding host)
# Apex marketing stays on APP_BASE_DOMAIN.

Seeds::DemoWedding.call
Rails.logger.info "Seeded demo wedding '#{Seeds::DemoWedding::SLUG}' (#{Seeds::DemoWedding::ADMIN_EMAIL} / #{Seeds::DemoWedding::ADMIN_PASSWORD})"

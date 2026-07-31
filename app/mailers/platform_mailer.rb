# Product emails to the couple/admin (welcome, billing, schedule lock, congrats).
# Uses the platform/admin visual language — cool ink + forest accent — not the
# guest wedding invitation stationery.
class PlatformMailer < ApplicationMailer
  layout "platform_mailer"
  skip_before_action :attach_inline_assets

  default from: -> {
    email_address_with_name(
      ENV.fetch("SMTP_USERNAME", "noreply@vowd.site"),
      "Vowd"
    )
  }

  private

  def sender_display_name
    "Vowd"
  end
end

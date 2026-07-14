class ApplicationMailer < ActionMailer::Base
  DIVIDER_IMAGE = "divider-leaf.png".freeze

  default from: -> { default_from_address }
  layout "mailer"
  helper ApplicationHelper
  helper WeddingHelper
  before_action :attach_inline_assets

  private

  def default_from_address
    email_address_with_name(
      ENV.fetch("SMTP_USERNAME", "noreply@vowd.site"),
      sender_display_name
    )
  end

  def sender_display_name
    couple = @wedding&.couple
    return "Wedding" if couple.blank?

    partners = [couple["partner1"], couple["partner2"]].compact_blank
    return "#{partners.join(' and ')}'s Wedding" if partners.any?

    "Wedding"
  end

  # Inline (CID) attachment so the botanical divider renders across clients that
  # strip inline SVG (Gmail, Outlook), unlike an embedded <svg> or data URI.
  def attach_inline_assets
    path = Rails.root.join("app/assets/images/botanical", DIVIDER_IMAGE)
    attachments.inline[DIVIDER_IMAGE] = File.binread(path)
  end
end

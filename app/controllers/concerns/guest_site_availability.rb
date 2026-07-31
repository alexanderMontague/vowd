# Halts guest-facing controllers when a wedding's trial has ended without payment.
# Paid sites stay live indefinitely (one-time Wedding Pass).
module GuestSiteAvailability
  extend ActiveSupport::Concern

  included do
    prepend_before_action :ensure_guest_site_live!
  end

  private

  def ensure_guest_site_live!
    wedding = current_wedding
    return if wedding.blank?
    return if wedding.public_site_live?

    render template: "public/unavailable/show",
           layout: "unavailable",
           status: :service_unavailable
  end
end

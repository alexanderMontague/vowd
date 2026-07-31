module BillingGate
  extend ActiveSupport::Concern

  included do
    before_action :require_billing_access!
  end

  private

  def require_billing_access!
    return unless Billing.enabled?
    return unless current_wedding
    return if billing_controller?
    return if current_wedding.billing_access?

    redirect_to admin_billing_path,
                alert: "Your trial has ended and the guest site is offline. Complete checkout to bring it back."
  end

  def billing_controller?
    is_a?(Admin::BillingController)
  end
end

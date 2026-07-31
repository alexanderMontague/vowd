module Admin
  class BillingController < Admin::BaseController
    def show
      @billing_enabled = Billing.enabled?
      @trial_days_remaining = trial_days_remaining
    end

    def checkout
      unless Billing.enabled?
        redirect_to admin_billing_path, alert: "Billing is not configured yet."
        return
      end

      session = Billing::CheckoutSessionCreator.call(
        wedding: current_wedding,
        success_url: admin_billing_url(checkout: "success"),
        cancel_url: admin_billing_url(checkout: "canceled")
      )

      redirect_to session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      redirect_to admin_billing_path, alert: e.message
    end

    def portal
      unless Billing.enabled?
        redirect_to admin_billing_path, alert: "Billing is not configured yet."
        return
      end

      if current_wedding.stripe_customer_id.blank?
        redirect_to admin_billing_path, alert: "No billing account yet. Start checkout first."
        return
      end

      session = Billing::PortalSessionCreator.call(
        wedding: current_wedding,
        return_url: admin_billing_url
      )

      redirect_to session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      redirect_to admin_billing_path, alert: e.message
    end

    private

    def trial_days_remaining
      return unless current_wedding.trial_active? && current_wedding.trial_ends_at

      days = ((current_wedding.trial_ends_at - Time.current) / 1.day).ceil
      [days, 0].max
    end
  end
end

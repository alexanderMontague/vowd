module Billing
  class PortalSessionCreator
    def self.call(wedding:, return_url:)
      new(wedding: wedding, return_url: return_url).call
    end

    def initialize(wedding:, return_url:)
      @wedding = wedding
      @return_url = return_url
    end

    def call
      raise "Billing is not configured" unless Billing.enabled?
      raise "No Stripe customer for this wedding" if @wedding.stripe_customer_id.blank?

      Billing.configure_stripe!
      Stripe::BillingPortal::Session.create(
        customer: @wedding.stripe_customer_id,
        return_url: @return_url
      )
    end
  end
end

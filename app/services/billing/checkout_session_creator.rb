module Billing
  class CheckoutSessionCreator
    def self.call(wedding:, success_url:, cancel_url:)
      new(wedding: wedding, success_url: success_url, cancel_url: cancel_url).call
    end

    def initialize(wedding:, success_url:, cancel_url:)
      @wedding = wedding
      @success_url = success_url
      @cancel_url = cancel_url
    end

    def call
      raise "Billing is not configured" unless Billing.enabled?

      Billing.configure_stripe!
      customer_id = CustomerFinder.call(@wedding)

      Stripe::Checkout::Session.create(
        mode: Billing.checkout_mode,
        customer: customer_id,
        client_reference_id: @wedding.id,
        success_url: @success_url,
        cancel_url: @cancel_url,
        line_items: [{ price: Billing.price_id, quantity: 1 }],
        metadata: { wedding_id: @wedding.id },
        allow_promotion_codes: true
      )
    end
  end
end

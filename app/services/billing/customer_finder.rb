module Billing
  class CustomerFinder
    def self.call(wedding)
      new(wedding).call
    end

    def initialize(wedding)
      @wedding = wedding
    end

    def call
      Billing.configure_stripe!
      return @wedding.stripe_customer_id if @wedding.stripe_customer_id.present?

      customer = Stripe::Customer.create(
        email: @wedding.admin_user&.email,
        name: @wedding.title,
        metadata: { wedding_id: @wedding.id }
      )

      @wedding.update!(stripe_customer_id: customer.id)
      customer.id
    end
  end
end

require "test_helper"

class BillingWebhookProcessorTest < ActiveSupport::TestCase
  setup do
    @wedding = create_wedding(
      id: "billed-wedding",
      billing_status: "trialing",
      trial_ends_at: 2.days.from_now,
      stripe_customer_id: "cus_test_123"
    )
  end

  test "checkout.session.completed activates one-time payment" do
    session = stripe_object(
      mode: "payment",
      payment_status: "paid",
      customer: "cus_test_123",
      client_reference_id: @wedding.id,
      subscription: nil,
      metadata: { "wedding_id" => @wedding.id }
    )

    Billing::WebhookProcessor.call(stripe_event("checkout.session.completed", session))

    @wedding.reload
    assert_equal "active", @wedding.billing_status
  end

  test "customer.subscription.updated syncs status and period end" do
    subscription = stripe_object(
      id: "sub_test_123",
      customer: "cus_test_123",
      status: "active",
      current_period_end: 1.month.from_now.to_i,
      metadata: {}
    )

    Billing::WebhookProcessor.call(stripe_event("customer.subscription.updated", subscription))

    @wedding.reload
    assert_equal "active", @wedding.billing_status
    assert_equal "sub_test_123", @wedding.stripe_subscription_id
    assert_in_delta 1.month.from_now, @wedding.billing_period_end, 2.seconds
  end

  test "customer.subscription.deleted marks canceled" do
    @wedding.update!(stripe_subscription_id: "sub_test_123", billing_status: "active")
    subscription = stripe_object(
      id: "sub_test_123",
      customer: "cus_test_123",
      status: "canceled",
      current_period_end: Time.current.to_i,
      metadata: {}
    )

    Billing::WebhookProcessor.call(stripe_event("customer.subscription.deleted", subscription))

    assert_equal "canceled", @wedding.reload.billing_status
  end

  private

  def stripe_event(type, object)
    Stripe::Event.construct_from(
      id: "evt_test",
      object: "event",
      type: type,
      data: { object: object.to_hash }
    )
  end

  def stripe_object(**attrs)
    Stripe::StripeObject.construct_from(attrs)
  end
end

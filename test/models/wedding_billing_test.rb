require "test_helper"

class WeddingBillingTest < ActiveSupport::TestCase
  test "billing_access is always true when stripe is not configured" do
    wedding = create_wedding(billing_status: "canceled")

    assert_not Billing.enabled?
    assert wedding.billing_access?
  end

  test "trialing wedding loses access after trial ends when billing enabled" do
    wedding = create_wedding(billing_status: "trialing", trial_ends_at: 1.hour.ago)

    with_env("STRIPE_SECRET_KEY" => "sk_test_x", "STRIPE_PRICE_ID" => "price_x") do
      assert_not wedding.billing_access?
      assert wedding.billing_requires_payment?
    end
  end

  test "active wedding keeps access when billing enabled" do
    wedding = create_wedding(billing_status: "active")

    with_env("STRIPE_SECRET_KEY" => "sk_test_x", "STRIPE_PRICE_ID" => "price_x") do
      assert wedding.billing_access?
      assert wedding.public_site_live?
    end
  end

  test "schedule is locked within 24 hours of ceremony start" do
    travel_to Time.zone.parse("2027-07-10 12:00:00") do
      wedding = create_wedding(
        date: Date.new(2027, 7, 10),
        ceremony_time: "4:00 PM",
        timezone: "America/Toronto"
      )

      assert wedding.schedule_locked?
      assert_not wedding.update(date: Date.new(2028, 1, 1))
      assert_includes wedding.errors[:date].join, "24 hours"
    end
  end

  test "schedule can be edited more than 24 hours before ceremony" do
    travel_to Time.zone.parse("2027-07-01 12:00:00") do
      wedding = create_wedding(
        date: Date.new(2027, 7, 10),
        ceremony_time: "4:00 PM",
        timezone: "America/Toronto"
      )

      assert_not wedding.schedule_locked?
      assert wedding.update(date: Date.new(2027, 7, 11))
    end
  end

  test "title remains editable after schedule lock" do
    travel_to Time.zone.parse("2027-07-10 12:00:00") do
      wedding = create_wedding(
        date: Date.new(2027, 7, 10),
        ceremony_time: "4:00 PM",
        timezone: "America/Toronto",
        title: "Before"
      )

      assert wedding.schedule_locked?
      assert wedding.update(title: "After")
      assert_equal "After", wedding.reload.title
    end
  end
end

require "test_helper"

class GuestSiteAvailabilityTest < ActionDispatch::IntegrationTest
  setup do
    @wedding = create_wedding(
      id: "offline-wedding",
      billing_status: "trialing",
      trial_ends_at: 1.day.ago
    )
    host_wedding!(@wedding)
  end

  test "public site is unavailable after unpaid trial when billing is enabled" do
    with_env("STRIPE_SECRET_KEY" => "sk_test_x", "STRIPE_PRICE_ID" => "price_x") do
      get root_path

      assert_response :service_unavailable
      assert_match(/temporarily unavailable/i, response.body)
    end
  end

  test "public site stays live for paid weddings" do
    @wedding.update!(billing_status: "active")

    with_env("STRIPE_SECRET_KEY" => "sk_test_x", "STRIPE_PRICE_ID" => "price_x") do
      get root_path

      assert_response :success
      assert_no_match(/temporarily unavailable/i, response.body)
    end
  end

  test "public site stays live when billing is not configured" do
    get root_path

    assert_response :success
  end
end

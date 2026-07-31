require "test_helper"

module Admin
  class BillingControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding(
        billing_status: "trialing",
        trial_ends_at: 3.days.from_now
      )
      @admin = create_admin_for(@wedding)
      sign_in_admin(@admin)
    end

    test "show renders billing page when stripe is disabled" do
      get admin_billing_path

      assert_response :success
      assert_select "h1, .admin-page-header", text: /Billing/i
      assert_match(/not configured/i, response.body)
    end

    test "expired trial redirects other admin pages to billing when enabled" do
      @wedding.update!(billing_status: "trialing", trial_ends_at: 1.day.ago)

      with_env(
        "STRIPE_SECRET_KEY" => "sk_test_dummy",
        "STRIPE_PRICE_ID" => "price_dummy"
      ) do
        get admin_root_path

        assert_redirected_to admin_billing_path
      end
    end

    test "billing page remains reachable when trial expired" do
      @wedding.update!(billing_status: "trialing", trial_ends_at: 1.day.ago)

      with_env(
        "STRIPE_SECRET_KEY" => "sk_test_dummy",
        "STRIPE_PRICE_ID" => "price_dummy"
      ) do
        get admin_billing_path

        assert_response :success
      end
    end
  end
end

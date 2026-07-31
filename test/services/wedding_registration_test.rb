require "test_helper"

class WeddingRegistrationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "success creates wedding and admin user" do
    assert_enqueued_jobs 1, only: AdminLifecycleDeliveryJob do
      result = WeddingRegistration.call(
        email: "couple@example.com",
        password: "password",
        password_confirmation: "password",
        slug: "britt-and-alex",
        title: "Britt & Alex",
        partner1: "Britt",
        partner2: "Alex"
      )

      assert result[:success]
      assert_equal "britt-and-alex", result[:wedding].id
      assert_equal "Britt & Alex", result[:wedding].title
      assert_equal "couple@example.com", result[:admin_user].email
      assert_equal result[:wedding].id, result[:admin_user].wedding_id
      assert_equal "trialing", result[:wedding].billing_status
      assert_in_delta Billing.trial_days.days.from_now, result[:wedding].trial_ends_at, 5.seconds
      assert AdminNotificationDelivery.exists?(wedding_id: "britt-and-alex", kind: "welcome")
    end
  end

  test "duplicate slug fails" do
    create_wedding(id: "taken-slug")

    result = WeddingRegistration.call(
      email: "new@example.com",
      password: "password",
      password_confirmation: "password",
      slug: "taken-slug",
      title: "Taken"
    )

    assert_not result[:success]
    assert_nil result[:wedding]
    assert_nil result[:admin_user]
    assert result[:errors].any?
  end

  test "duplicate email fails" do
    wedding = create_wedding(id: "first-wedding")
    create_admin_for(wedding, email: "taken@example.com")

    result = WeddingRegistration.call(
      email: "taken@example.com",
      password: "password",
      password_confirmation: "password",
      slug: "second-wedding",
      title: "Second"
    )

    assert_not result[:success]
    assert_nil result[:wedding]
    assert_nil result[:admin_user]
    assert result[:errors].any?
    assert_nil Wedding.find_by(id: "second-wedding")
  end
end

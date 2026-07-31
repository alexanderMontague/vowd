require "test_helper"

class AdminLifecyclePipelineJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @wedding = create_wedding(
      id: "lifecycle-wedding",
      date: Date.new(2027, 7, 10),
      ceremony_time: "4:00 PM",
      timezone: "America/Toronto",
      billing_status: "trialing",
      trial_ends_at: Time.find_zone!("America/Toronto").local(2027, 6, 15, 12, 0)
    )
    create_admin_for(@wedding, email: "couple@example.com")
  end

  test "enqueues trial expiring email three days before trial ends" do
    with_env("STRIPE_SECRET_KEY" => "sk_test_x", "STRIPE_PRICE_ID" => "price_x") do
      assert_enqueued_with(job: AdminLifecycleDeliveryJob) do
        AdminLifecyclePipelineJob.perform_now(
          reference_time: Time.find_zone!("America/Toronto").local(2027, 6, 12, 10, 0)
        )
      end
    end

    assert AdminNotificationDelivery.exists?(wedding_id: @wedding.id, kind: "trial_expiring_3d")
  end

  test "enqueues schedule locking email 24 hours before ceremony" do
    assert_enqueued_with(job: AdminLifecycleDeliveryJob) do
      AdminLifecyclePipelineJob.perform_now(
        reference_time: Time.find_zone!("America/Toronto").local(2027, 7, 9, 16, 0)
      )
    end

    assert AdminNotificationDelivery.exists?(wedding_id: @wedding.id, kind: "schedule_locking")
  end

  test "enqueues congrats the day after for paid weddings" do
    @wedding.update!(billing_status: "active")

    with_env("STRIPE_SECRET_KEY" => "sk_test_x", "STRIPE_PRICE_ID" => "price_x") do
      assert_enqueued_with(job: AdminLifecycleDeliveryJob) do
        AdminLifecyclePipelineJob.perform_now(
          reference_time: Time.find_zone!("America/Toronto").local(2027, 7, 11, 10, 0)
        )
      end
    end

    assert AdminNotificationDelivery.exists?(wedding_id: @wedding.id, kind: "wedding_congrats")
  end

  test "does not enqueue congrats for unpaid weddings when billing enabled" do
    @wedding.update!(billing_status: "trialing", trial_ends_at: 1.day.ago)

    with_env("STRIPE_SECRET_KEY" => "sk_test_x", "STRIPE_PRICE_ID" => "price_x") do
      assert_no_enqueued_jobs(only: AdminLifecycleDeliveryJob) do
        AdminLifecyclePipelineJob.perform_now(
          reference_time: Time.find_zone!("America/Toronto").local(2027, 7, 11, 10, 0)
        )
      end
    end
  end

  test "delivery job sends mail and marks sent" do
    delivery = AdminNotificationDelivery.create!(
      wedding_id: @wedding.id,
      kind: "welcome",
      status: "queued"
    )

    assert_emails 1 do
      AdminLifecycleDeliveryJob.perform_now(delivery.id)
    end

    assert_equal "sent", delivery.reload.status
    assert_not_nil delivery.sent_at
  end
end

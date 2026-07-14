require "test_helper"

class WeddingReminderPipelineJobTest < ActiveJob::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    clear_enqueued_jobs
    clear_performed_jobs

    wedding = create_wedding
    household = Household.create!(wedding_id: wedding.id, name: "Reminder Household")
    Guest.create!(
      wedding_id: wedding.id,
      household: household,
      first_name: "Alex",
      last_name: "Guest",
      email: "alex.guest@example.com",
      phone_number: "+15550001234"
    )

    # Derive the trigger time from the wedding date so the test stays valid as
    # wedding dates change. 10:05 is just past the 10:00 send window.
    week_before = wedding.date - 7
    @week_before_send_time = Time.find_zone!(wedding.timezone)
                                 .local(week_before.year, week_before.month, week_before.day, 10, 5)
  end

  test "enqueues one delivery per guest and reminder channel" do
    travel_to(@week_before_send_time) do
      WeddingReminderPipelineJob.perform_now
    end

    assert_equal 1, NotificationDelivery.count
    assert_equal "week_before", NotificationDelivery.first.reminder_key
    assert_equal "email", NotificationDelivery.first.channel
    assert_enqueued_jobs 1, only: WeddingReminderDeliveryJob
  end

  test "does not enqueue duplicate deliveries across repeated runs" do
    travel_to(@week_before_send_time) do
      WeddingReminderPipelineJob.perform_now
      WeddingReminderPipelineJob.perform_now
    end

    assert_equal 1, NotificationDelivery.count
    assert_enqueued_jobs 1, only: WeddingReminderDeliveryJob
  end
end

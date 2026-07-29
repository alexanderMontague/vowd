require "test_helper"

module WeddingReminders
  class PreviewTest < ActiveSupport::TestCase
    test "renders subject and html body for a reminder rule" do
      wedding = create_wedding(title: "Britt & Alex")
      rule = Configuration::ReminderRule.new(
        key: "week_before",
        days_before: 7,
        channels: ["email"],
        email_subject: "One week to go",
        audiences: ["pending_rsvp"]
      )

      preview = Preview.call(wedding:, reminder_rule: rule)

      assert_equal "One week to go", preview[:subject]
      assert_includes preview[:html], "Hi Alex,"
      assert_includes preview[:html], "Britt &amp; Alex"
    end
  end
end

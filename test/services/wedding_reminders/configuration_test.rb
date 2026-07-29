require "test_helper"

module WeddingReminders
  class ConfigurationTest < ActiveSupport::TestCase
    test "returns due rules based on wedding date" do
      wedding = create_wedding
      configuration = Configuration.new(wedding:)

      week_before_date = wedding.date - 7
      due_keys = configuration.due_rules_on(week_before_date).map(&:key)

      assert_includes due_keys, "week_before"
    end

    test "uses configured timezone and send window" do
      wedding = create_wedding(timezone: "America/Toronto")
      configuration = Configuration.new(wedding:)

      before_window = Time.find_zone!("America/Toronto").local(2026, 8, 29, 9, 59)
      after_window = Time.find_zone!("America/Toronto").local(2026, 8, 29, 10, 0)

      assert_not configuration.send_window_open?(before_window)
      assert configuration.send_window_open?(after_window)
    end

    test "parses per-rule audiences and unions recipients distinctly" do
      wedding = create_wedding
      household = Household.create!(wedding_id: wedding.id, name: "Smith")
      pending_guest = Guest.create!(household:, first_name: "Pat", last_name: "Pending", email: "pat@example.com")
      accepted_guest = Guest.create!(household:, first_name: "Ada", last_name: "Accepted", email: "ada@example.com")
      accepted_guest.rsvp.update!(status: "accepted")

      wedding.update!(
        notifications: {
          "reminders" => {
            "enabled" => true,
            "send_time" => "10:00",
            "channels" => { "email" => { "enabled" => true } },
            "schedule" => [
              {
                "key" => "week_before",
                "days_before" => 7,
                "channels" => ["email"],
                "audiences" => %w[pending_rsvp accepted],
                "email_subject" => "Soon"
              }
            ]
          }
        }
      )

      configuration = Configuration.new(wedding:)
      rule = configuration.rules.first

      assert_equal %w[pending_rsvp accepted], rule.audiences

      recipient_ids = configuration.recipients_scope(rule).pluck(:id)
      assert_includes recipient_ids, pending_guest.id
      assert_includes recipient_ids, accepted_guest.id
      assert_equal recipient_ids.uniq, recipient_ids
    end

    test "falls back to legacy global audience when rule audiences are blank" do
      wedding = create_wedding
      household = Household.create!(wedding_id: wedding.id, name: "Lee")
      Guest.create!(household:, first_name: "Sam", last_name: "Pending", email: "sam@example.com")
      accepted = Guest.create!(household:, first_name: "Kim", last_name: "Yes", email: "kim@example.com")
      accepted.rsvp.update!(status: "accepted")

      wedding.update!(
        notifications: {
          "reminders" => {
            "enabled" => true,
            "audience" => "accepted",
            "send_time" => "10:00",
            "channels" => { "email" => { "enabled" => true } },
            "schedule" => [
              {
                "key" => "day_of",
                "days_before" => 0,
                "channels" => ["email"],
                "email_subject" => "Today"
              }
            ]
          }
        }
      )

      configuration = Configuration.new(wedding:)
      rule = configuration.rules.first

      assert_equal ["accepted"], rule.audiences
      assert_equal [accepted.id], configuration.recipients_scope(rule).pluck(:id)
    end
  end
end

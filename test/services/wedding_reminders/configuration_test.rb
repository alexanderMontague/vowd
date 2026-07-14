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
  end
end

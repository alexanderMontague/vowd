module WeddingReminders
  class Configuration
    DEFAULT_TIMEZONE = "America/Toronto"
    DEFAULT_SEND_TIME = "10:00"
    DEFAULT_AUDIENCE = "pending_rsvp"
    VALID_AUDIENCES = %w[all pending_rsvp accepted declined].freeze
    DEFAULT_RULES = [
      { "key" => "week_before", "days_before" => 7, "channels" => ["email"] },
      { "key" => "day_before", "days_before" => 1, "channels" => ["email"] },
      { "key" => "day_of", "days_before" => 0, "channels" => ["email"] }
    ].freeze

    ReminderRule = Struct.new(:key, :days_before, :channels, :email_subject, keyword_init: true)

    def initialize(wedding:)
      @wedding = wedding
      @reminder_config = extract_reminder_config
    end

    def enabled?
      cast_boolean(@reminder_config.fetch("enabled", true))
    end

    def timezone
      value = @reminder_config["timezone"].presence || DEFAULT_TIMEZONE
      ActiveSupport::TimeZone[value]&.name || DEFAULT_TIMEZONE
    end

    def send_time
      raw_value = @reminder_config["send_time"].to_s
      return DEFAULT_SEND_TIME unless raw_value.match?(/\A\d{2}:\d{2}\z/)

      raw_value
    end

    def audience
      configured_audience = @reminder_config["audience"].to_s
      VALID_AUDIENCES.include?(configured_audience) ? configured_audience : DEFAULT_AUDIENCE
    end

    def channel_enabled?(channel)
      channel_config = @reminder_config.fetch("channels", {})
      configured_channel = channel_config.fetch(channel.to_s, {})
      cast_boolean(configured_channel.fetch("enabled", channel.to_s == "email"))
    end

    def rules
      configured_rules = @reminder_config.fetch("schedule", DEFAULT_RULES)
      configured_rules.filter_map.with_index do |rule, index|
        parsed_rule = parse_rule(rule, index)
        next if parsed_rule.channels.empty?

        parsed_rule
      end
    end

    def due_rules_on(date)
      rules.select { |rule| @wedding.date - rule.days_before == date }
    end

    def send_window_open?(time)
      local_time = time.in_time_zone(timezone)
      local_minutes = (local_time.hour * 60) + local_time.min
      send_hour, send_minute = send_time.split(":").map(&:to_i)
      scheduled_minutes = (send_hour * 60) + send_minute
      local_minutes >= scheduled_minutes
    end

    def recipients_scope
      base_scope = @wedding.guests.includes(:rsvp)

      case audience
      when "all" then base_scope
      when "accepted" then base_scope.rsvp_accepted
      when "declined" then base_scope.rsvp_declined
      else base_scope.rsvp_pending
      end
    end

    private

    def extract_reminder_config
      notifications = @wedding.attributes["notifications"]
      return {} unless notifications.is_a?(Hash)

      # Copy reminders so callers can safely merge without mutating stored JSON.
      reminders = deep_stringify_keys(notifications).fetch("reminders", {})
      reminders.merge("timezone" => @wedding.timezone)
    end

    def parse_rule(rule, index)
      raw_rule = deep_stringify_keys(rule)
      return unless raw_rule.is_a?(Hash)

      reminder_key = raw_rule["key"].presence || "reminder_#{index + 1}"
      configured_channels = Array(raw_rule["channels"]).map(&:to_s)
      filtered_channels = configured_channels.select do |channel|
        NotificationDelivery::CHANNELS.include?(channel) && channel_enabled?(channel)
      end

      ReminderRule.new(
        key: reminder_key,
        days_before: raw_rule["days_before"].to_i,
        channels: filtered_channels,
        email_subject: raw_rule["email_subject"].to_s
      )
    end

    def cast_boolean(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    def deep_stringify_keys(value)
      return value.deep_stringify_keys if value.respond_to?(:deep_stringify_keys)

      value
    end
  end
end

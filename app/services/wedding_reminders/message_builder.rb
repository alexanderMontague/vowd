module WeddingReminders
  class MessageBuilder
    DEFAULT_EMAIL_SUBJECT_PREFIX = "Wedding reminder"

    def initialize(wedding:, reminder_rule:)
      @wedding = wedding
      @reminder_rule = reminder_rule
    end

    def email_subject
      return @reminder_rule.email_subject if @reminder_rule.email_subject.present?

      "#{DEFAULT_EMAIL_SUBJECT_PREFIX}: #{wedding_title} in #{distance_label}"
    end

    def distance_label
      case @reminder_rule.days_before
      when 0 then "today"
      when 1 then "tomorrow"
      else "in #{@reminder_rule.days_before} days"
      end
    end

    private

    def wedding_title
      @wedding.title
    end
  end
end

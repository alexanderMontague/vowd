module WeddingReminders
  class Preview
    SampleGuest = Struct.new(:first_name, :invite_code, :email, keyword_init: true)

    def self.call(wedding:, reminder_rule:, guest: nil)
      new(wedding:, reminder_rule:, guest:).call
    end

    def initialize(wedding:, reminder_rule:, guest: nil)
      @wedding = wedding
      @reminder_rule = reminder_rule
      @guest = guest
    end

    def call
      guest = resolve_guest
      message_builder = MessageBuilder.new(wedding: @wedding, reminder_rule: @reminder_rule)
      mail = WeddingReminderMailer.reminder(
        guest: guest,
        wedding: @wedding,
        subject: message_builder.email_subject
      )

      {
        subject: mail.subject,
        html: mail.html_part&.body&.decoded.presence || mail.body.decoded
      }
    end

    private

    def resolve_guest
      return @guest if @guest.present?

      existing = @wedding.guests.order(:created_at).detect { |guest| guest.email.present? }
      return existing if existing

      SampleGuest.new(first_name: "Alex", invite_code: "PREVIEW123", email: "preview@example.com")
    end
  end
end

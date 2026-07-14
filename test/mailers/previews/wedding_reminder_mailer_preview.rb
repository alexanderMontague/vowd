# Preview at http://localhost:3003/rails/mailers/wedding_reminder_mailer/reminder
class WeddingReminderMailerPreview < ActionMailer::Preview
  def reminder
    wedding = preview_wedding
    WeddingReminderMailer.reminder(
      guest: EmailSampleData.accepted_guest(wedding:),
      wedding:,
      subject: "Your wedding RSVP: one week to go"
    )
  end

  private

  def preview_wedding
    Wedding.first || raise("No wedding found. Create a Wedding before previewing mailers.")
  end
end

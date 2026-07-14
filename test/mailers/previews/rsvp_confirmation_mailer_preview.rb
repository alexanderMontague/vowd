# Preview at http://localhost:3003/rails/mailers/rsvp_confirmation_mailer/confirmation
class RSVPConfirmationMailerPreview < ActionMailer::Preview
  def confirmation
    wedding = preview_wedding
    RSVPConfirmationMailer.confirmation(
      guests: [
        EmailSampleData.accepted_guest(wedding:),
        EmailSampleData.declined_guest(wedding:)
      ],
      wedding:
    )
  end

  private

  def preview_wedding
    Wedding.first || raise("No wedding found. Create a Wedding before previewing mailers.")
  end
end

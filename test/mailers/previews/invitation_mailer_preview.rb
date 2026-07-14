# Preview at http://localhost:3003/rails/mailers/invitation_mailer/invite
class InvitationMailerPreview < ActionMailer::Preview
  def invite
    wedding = Wedding.first || raise("No wedding found. Create a Wedding before previewing mailers.")
    InvitationMailer.invite(EmailSampleData.accepted_guest(wedding:))
  end
end

class SaveTheDateSignupService
  def self.submit!(wedding:, signup_params:)
    signup = SaveTheDateSignup.new(signup_params.merge(wedding_id: wedding.id))

    ActiveRecord::Base.transaction do
      signup.save!
      auto_match_to_guest!(wedding: wedding, signup: signup)
    end

    { success: true, signup: signup }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.record.errors.full_messages.to_sentence.presence || e.message }
  rescue StandardError
    { success: false, error: "Something went wrong saving your details. Please try again." }
  end

  # Links the signup to an existing guest whose email matches, and backfills
  # contact details onto the guest record so the couple has them in one place.
  def self.auto_match_to_guest!(wedding:, signup:)
    guest = wedding.guests.with_email.find_by("LOWER(email) = ?", signup.email)
    return unless guest

    link!(signup: signup, guest: guest)
  end

  def self.link!(signup:, guest:)
    guest.email = signup.email if guest.email.blank?
    guest.phone_number = signup.phone_number if guest.phone_number.blank? && signup.phone_number.present?
    guest.save! if guest.changed?

    signup.update!(guest: guest, matched_at: Time.current)
  end
end

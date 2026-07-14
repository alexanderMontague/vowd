# Builds in-memory sample records for exercising mailers without touching the
# database. Shared by ActionMailer previews (/rails/mailers) and the
# `email:test` rake task so sample content stays consistent in one place.
module EmailSampleData
  module_function

  def accepted_guest(email: "sample.guest@example.com", wedding: nil)
    wedding = resolve_wedding(wedding)
    build_guest("Sample", "Guest", email, wedding).tap do |guest|
      guest.build_rsvp(status: "accepted", meal_choice: Array(wedding.meal_options).first)
    end
  end

  def declined_guest(email: "sample.partner@example.com", wedding: nil)
    wedding = resolve_wedding(wedding)
    build_guest("Sample", "Partner", email, wedding).tap do |guest|
      guest.build_rsvp(status: "declined")
    end
  end

  def build_guest(first_name, last_name, email, wedding = nil)
    wedding = resolve_wedding(wedding)
    Guest.new(
      first_name:,
      last_name:,
      email:,
      invite_code: "SAMPLECODE",
      wedding_id: wedding.id
    )
  end

  def resolve_wedding(wedding)
    return wedding if wedding

    Wedding.first || raise(ArgumentError, "No wedding found. Pass wedding: or create a Wedding first.")
  end
end

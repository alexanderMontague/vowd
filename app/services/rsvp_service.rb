class RSVPService
  def self.submit!(household:, rsvp_params:)
    ActiveRecord::Base.transaction do
      rsvp_params.each do |guest_id, attributes|
        guest = household.guests.find(guest_id)
        rsvp = guest.rsvp || guest.build_rsvp

        rsvp.update!(
          status: attributes[:status],
          meal_choice: attributes[:status] == "accepted" ? attributes[:meal_choice] : nil,
          dietary_restrictions: attributes[:dietary_restrictions],
          song_request: attributes[:song_request],
          notes: attributes[:notes]
        )
      end
    end

    # Enqueued after commit so the async worker never reads stale/uncommitted data.
    RSVPConfirmationJob.perform_later(household.id)

    { success: true }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.message }
  rescue StandardError
    { success: false, error: "An error occurred while saving your RSVP. Please try again." }
  end
end

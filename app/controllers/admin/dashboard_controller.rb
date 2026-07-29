module Admin
  class DashboardController < Admin::BaseController
    def index
      @stats = calculate_stats
      @upcoming_events = current_wedding&.events&.upcoming&.limit(5) || []
      @recent_rsvps = RSVP.joins(:guest)
                          .where(guests: { wedding_id: current_wedding&.id })
                          .where.not(status: "pending")
                          .order(updated_at: :desc)
                          .limit(10)
      @guest_shoutouts = guest_shoutouts
    end

    private

    def guest_shoutouts
      return RSVP.none unless current_wedding

      RSVP.includes(:guest)
          .where(guests: { wedding_id: current_wedding.id })
          .where("song_request IS NOT NULL AND song_request != '' OR notes IS NOT NULL AND notes != ''")
          .references(:guest)
          .order(updated_at: :desc)
    end

    def calculate_stats
      return default_stats unless current_wedding

      guests = current_wedding.guests
      rsvps = RSVP.where(guest_id: guests.pluck(:id))

      {
        total_guests: guests.count,
        accepted: rsvps.accepted.count,
        declined: rsvps.declined.count,
        pending: rsvps.pending.count,
        acceptance_rate: calculate_acceptance_rate(rsvps),
        invitations_sent: Invitation.where(guest_id: guests.pluck(:id)).sent.count,
        save_the_date_responses: current_wedding.save_the_date_signups.count
      }
    end

    def calculate_acceptance_rate(rsvps)
      total_responses = rsvps.accepted.count + rsvps.declined.count
      return 0 if total_responses.zero?

      ((rsvps.accepted.count.to_f / total_responses) * 100).round(1)
    end

    def default_stats
      {
        total_guests: 0,
        accepted: 0,
        declined: 0,
        pending: 0,
        acceptance_rate: 0,
        invitations_sent: 0,
        save_the_date_responses: 0
      }
    end
  end
end

module Admin
  class SaveTheDateSignupsController < Admin::BaseController
    before_action :set_signup, only: %i[match unmatch destroy]

    def index
      @signups = current_wedding.save_the_date_signups
                                .includes(guest: :household)
                                .recent_first

      @signups = @signups.matched if params[:status] == "matched"
      @signups = @signups.unmatched if params[:status] == "unmatched"

      matched_guest_ids = current_wedding.save_the_date_signups.matched.pluck(:guest_id)
      @guests = current_wedding.guests
                               .where.not(id: matched_guest_ids)
                               .includes(:household)
                               .order(:last_name, :first_name)
    end

    def match
      guest = current_wedding.guests.find(params[:guest_id])
      SaveTheDateSignupService.link!(signup: @signup, guest: guest)
      redirect_to admin_save_the_date_signups_path,
                  notice: "Matched #{@signup.email} to #{guest.full_name}."
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_save_the_date_signups_path, alert: "Please choose a guest to match."
    end

    def unmatch
      @signup.update!(guest: nil, matched_at: nil)
      redirect_to admin_save_the_date_signups_path, notice: "Match removed."
    end

    def destroy
      @signup.destroy
      redirect_to admin_save_the_date_signups_path, notice: "Signup removed."
    end

    private

    def set_signup
      @signup = current_wedding.save_the_date_signups.find(params[:id])
    end
  end
end

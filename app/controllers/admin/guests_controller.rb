require "csv"

module Admin
  class GuestsController < Admin::BaseController
    before_action :set_guest, only: %i[show edit update destroy]

    def index
      @guests = current_wedding.guests
                               .includes(:household, :rsvp)
                               .order(:last_name, :first_name)

      @guests = apply_filters(@guests)
      @households = current_wedding.households.order(:name)
    end

    def show
      redirect_to edit_admin_guest_path(@guest)
    end

    def new
      redirect_to new_admin_household_path, notice: "Please create guests via the household form"
    end

    def edit
      @households = current_wedding.households.order(:name)
    end

    def create
      redirect_to new_admin_household_path, notice: "Please create guests via the household form"
    end

    def update
      if @guest.update(guest_params)
        redirect_to admin_guests_path, notice: "Guest updated successfully"
      else
        @households = current_wedding.households.order(:name)
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @guest.destroy
      redirect_to admin_guests_path, notice: "Guest removed successfully"
    end

    def export
      @guests = current_wedding.guests.includes(:household, :rsvp)

      respond_to do |format|
        format.csv do
          send_data generate_csv(@guests),
                    filename: "guests-#{Time.zone.today}.csv",
                    type: "text/csv"
        end
      end
    end

    private

    def set_guest
      @guest = current_wedding.guests.find(params[:id])
    end

    def guest_params
      params.require(:guest).permit(
        :household_id, :first_name, :last_name, :email,
        :address, :phone_number
      )
    end

    def apply_filters(guests)
      guests = guests.where(household_id: params[:household_id]) if params[:household_id].present?

      guests = guests.joins(:rsvp).where(rsvps: { status: params[:rsvp_status] }) if params[:rsvp_status].present?

      guests
    end

    def generate_csv(guests)
      CSV.generate(headers: true) do |csv|
        csv << ["First Name", "Last Name", "Email", "Phone", "Household", "RSVP Status", "Meal Choice",
                "Dietary Restrictions", "Song Request", "Message to the Couple"]

        guests.each do |guest|
          csv << [
            guest.first_name,
            guest.last_name,
            guest.email,
            guest.phone_number,
            guest.household.display_name,
            guest.rsvp&.status,
            guest.rsvp&.meal_choice,
            guest.rsvp&.dietary_restrictions,
            guest.rsvp&.song_request,
            guest.rsvp&.notes
          ]
        end
      end
    end
  end
end

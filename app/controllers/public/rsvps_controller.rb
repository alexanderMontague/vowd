module Public
  class RsvpsController < Public::BaseController
    before_action :set_guest, only: %i[edit update thanks]
    before_action :check_rsvp_open, except: :thanks

    def index
    end

    def search
      query = params[:q].to_s.strip
      @results = []

      if query.length >= 2
        @results = current_wedding.guests
                                  .includes(:household)
                                  .where("LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q", q: "%#{query.downcase}%")
                                  .limit(10)
                                  .map do |guest|
          {
            id: guest.id,
            name: guest.full_name,
            household: guest.household.display_name,
            invite_code: guest.invite_code
          }
        end
      end

      render json: @results
    end

    def edit
      @household = @guest.household
      @guests = @household.guests.includes(:rsvp)
      @meal_options = current_wedding.meal_options

      return unless @household.rsvpd?

      flash.now[:notice] = "Thank you for your RSVP!"
    end

    def update
      result = RSVPService.submit!(
        household: @guest.household,
        rsvp_params: rsvp_params
      )

      if result[:success]
        redirect_to public_rsvp_thanks_path(@guest.invite_code),
                    notice: "Thank you for your RSVP!"
      else
        @household = @guest.household
        @guests = @household.guests.includes(:rsvp)
        @meal_options = current_wedding.meal_options
        flash.now[:alert] = result[:error]
        render :edit, status: :unprocessable_content
      end
    end

    def thanks
    end

    private

    def set_guest
      @guest = current_wedding.guests.find_by!(invite_code: params[:code])
    end

    def rsvp_params
      params.require(:rsvps).permit!
    end

    # The RSVP page explains itself rather than 404ing, so it consults navigation
    # directly instead of declaring a `guest_page`.
    def check_rsvp_open
      return if site_navigation.visible?("rsvp")

      respond_to do |format|
        format.html { render :closed, status: :not_found }
        format.json { render json: { error: "RSVPs are closed." }, status: :forbidden }
      end
    end
  end
end

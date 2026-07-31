module Party
  class BaseController < ApplicationController
    include WeddingConcern
    include GuestSiteAvailability

    layout "party"

    before_action :require_wedding!
    before_action :set_board

    helper_method :current_party_member

    private

    def set_board
      @board = current_wedding.party_boards.find_by(share_token: params[:token])
      return if @board

      render plain: "This party link is invalid or has been replaced.", status: :not_found
    end

    def current_party_member
      return @current_party_member if defined?(@current_party_member)

      member_id = cookies.signed[member_cookie_key]
      @current_party_member = member_id.present? ? @board.members.find_by(id: member_id) : nil
    end

    def member_cookie_key
      "party_member_#{@board.id}"
    end

    def remember_member!(member)
      cookies.signed[member_cookie_key] = {
        value: member.id,
        expires: 30.days.from_now,
        httponly: true,
        same_site: :lax
      }
      @current_party_member = member
    end
  end
end

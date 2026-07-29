module Party
  class BoardsController < Party::BaseController
    def show
      @members = @board.members.ordered
      @ideas = @board.ideas.ordered
      @itinerary_items = @board.itinerary_items.ordered
      @polls = @board.polls.open.ordered.includes(:options, :votes)
    end

    def identify
      member = @board.members.find(params.require(:member_id))
      remember_member!(member)
      redirect_to party_board_path(token: @board.share_token), notice: "Welcome, #{member.name}."
    end
  end
end

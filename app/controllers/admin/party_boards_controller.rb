module Admin
  class PartyBoardsController < Admin::BaseController
    before_action :set_board

    def show
      load_board_associations
    end

    def update
      if @board.update(board_params)
        redirect_to admin_party_board_path(kind: @board.kind), notice: "Board updated."
      else
        load_board_associations
        flash.now[:alert] = @board.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    def sync
      PartyBoards::SyncFromWeddingParty.call(board: @board)
      redirect_to admin_party_board_path(kind: @board.kind), notice: "Synced from wedding party."
    end

    def regenerate_token
      @board.regenerate_share_token!
      redirect_to admin_party_board_path(kind: @board.kind), notice: "Share link regenerated. Old links no longer work."
    end

    private

    def set_board
      kind = params[:kind].to_s
      unless PartyBoard::KINDS.include?(kind)
        redirect_to admin_party_path, alert: "Unknown party board."
        return
      end

      @board = current_wedding.party_boards.find_or_create_by!(kind: kind) do |board|
        board.title = PartyBoard::DEFAULT_TITLES.fetch(kind)
      end
    end

    def load_board_associations
      @members = @board.members.ordered
      @ideas = @board.ideas.ordered
      @itinerary_items = @board.itinerary_items.ordered
      @polls = @board.polls.ordered.includes(:options, :votes)
      @share_url = "#{request.base_url}#{@board.share_path}"
    end

    def board_params
      params.require(:party_board).permit(:title, :notes, :status)
    end
  end
end

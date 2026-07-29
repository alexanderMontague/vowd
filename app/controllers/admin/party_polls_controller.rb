module Admin
  class PartyPollsController < Admin::BaseController
    before_action :set_board
    before_action :set_poll, only: %i[update destroy]

    def create
      poll = @board.polls.new(poll_params.merge(wedding_id: current_wedding.id))
      if poll.save
        redirect_to admin_party_board_path(kind: @board.kind), notice: "Poll created."
      else
        redirect_to admin_party_board_path(kind: @board.kind), alert: poll.errors.full_messages.to_sentence
      end
    end

    def update
      if @poll.update(poll_params)
        redirect_to admin_party_board_path(kind: @board.kind), notice: "Poll updated."
      else
        redirect_to admin_party_board_path(kind: @board.kind), alert: @poll.errors.full_messages.to_sentence
      end
    end

    def destroy
      @poll.destroy!
      redirect_to admin_party_board_path(kind: @board.kind), notice: "Poll removed."
    end

    private

    def set_board
      @board = current_wedding.party_boards.find_by!(kind: params[:party_board_kind])
    end

    def set_poll
      @poll = @board.polls.find(params[:id])
    end

    def poll_params
      params.require(:party_poll).permit(:title, :description, :status, :position)
    end
  end
end

module Admin
  class PartyPollOptionsController < Admin::BaseController
    before_action :set_board
    before_action :set_poll
    before_action :set_option, only: %i[update destroy]

    def create
      option = @poll.options.new(option_params.merge(wedding_id: current_wedding.id))
      if option.save
        redirect_to admin_party_board_path(kind: @board.kind), notice: "Option added."
      else
        redirect_to admin_party_board_path(kind: @board.kind), alert: option.errors.full_messages.to_sentence
      end
    end

    def update
      if @option.update(option_params)
        redirect_to admin_party_board_path(kind: @board.kind), notice: "Option updated."
      else
        redirect_to admin_party_board_path(kind: @board.kind), alert: @option.errors.full_messages.to_sentence
      end
    end

    def destroy
      @option.destroy!
      redirect_to admin_party_board_path(kind: @board.kind), notice: "Option removed."
    end

    private

    def set_board
      @board = current_wedding.party_boards.find_by!(kind: params[:party_board_kind])
    end

    def set_poll
      @poll = @board.polls.find(params[:poll_id])
    end

    def set_option
      @option = @poll.options.find(params[:id])
    end

    def option_params
      params.require(:party_poll_option).permit(:title, :price_text, :notes, :url, :position)
    end
  end
end

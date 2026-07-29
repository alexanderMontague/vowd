module Admin
  class PartyIdeasController < Admin::BaseController
    before_action :set_board
    before_action :set_idea, only: %i[update destroy]

    def create
      idea = @board.ideas.new(idea_params.merge(wedding_id: current_wedding.id))
      if idea.save
        redirect_to admin_party_board_path(kind: @board.kind), notice: "Idea added."
      else
        redirect_to admin_party_board_path(kind: @board.kind), alert: idea.errors.full_messages.to_sentence
      end
    end

    def update
      if @idea.update(idea_params)
        redirect_to admin_party_board_path(kind: @board.kind), notice: "Idea updated."
      else
        redirect_to admin_party_board_path(kind: @board.kind), alert: @idea.errors.full_messages.to_sentence
      end
    end

    def destroy
      @idea.destroy!
      redirect_to admin_party_board_path(kind: @board.kind), notice: "Idea removed."
    end

    private

    def set_board
      @board = current_wedding.party_boards.find_by!(kind: params[:party_board_kind])
    end

    def set_idea
      @idea = @board.ideas.find(params[:id])
    end

    def idea_params
      params.require(:party_idea).permit(:title, :body, :position)
    end
  end
end

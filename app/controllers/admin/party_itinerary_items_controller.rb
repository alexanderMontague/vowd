module Admin
  class PartyItineraryItemsController < Admin::BaseController
    before_action :set_board
    before_action :set_item, only: %i[update destroy]

    def create
      item = @board.itinerary_items.new(item_params.merge(wedding_id: current_wedding.id))
      if item.save
        redirect_to admin_party_board_path(kind: @board.kind), notice: "Itinerary stop added."
      else
        redirect_to admin_party_board_path(kind: @board.kind), alert: item.errors.full_messages.to_sentence
      end
    end

    def update
      if @item.update(item_params)
        redirect_to admin_party_board_path(kind: @board.kind), notice: "Itinerary stop updated."
      else
        redirect_to admin_party_board_path(kind: @board.kind), alert: @item.errors.full_messages.to_sentence
      end
    end

    def destroy
      @item.destroy!
      redirect_to admin_party_board_path(kind: @board.kind), notice: "Itinerary stop removed."
    end

    private

    def set_board
      @board = current_wedding.party_boards.find_by!(kind: params[:party_board_kind])
    end

    def set_item
      @item = @board.itinerary_items.find(params[:id])
    end

    def item_params
      params.require(:party_itinerary_item).permit(:occurs_on, :starts_at_text, :title, :location, :notes, :position)
    end
  end
end

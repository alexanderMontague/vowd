module Admin
  class PartyMembersController < Admin::BaseController
    before_action :set_board
    before_action :set_member, only: %i[update destroy]

    def create
      member = @board.members.new(member_params.merge(wedding_id: current_wedding.id, source: "custom"))
      if member.save
        redirect_to admin_party_board_path(kind: @board.kind), notice: "Member added."
      else
        redirect_to admin_party_board_path(kind: @board.kind), alert: member.errors.full_messages.to_sentence
      end
    end

    def update
      if @member.update(member_params)
        redirect_to admin_party_board_path(kind: @board.kind), notice: "Member updated."
      else
        redirect_to admin_party_board_path(kind: @board.kind), alert: @member.errors.full_messages.to_sentence
      end
    end

    def destroy
      @member.destroy!
      redirect_to admin_party_board_path(kind: @board.kind), notice: "Member removed."
    end

    private

    def set_board
      @board = current_wedding.party_boards.find_by!(kind: params[:party_board_kind])
    end

    def set_member
      @member = @board.members.find(params[:id])
    end

    def member_params
      params.require(:party_member).permit(:name, :role, :email, :phone_number, :position)
    end
  end
end

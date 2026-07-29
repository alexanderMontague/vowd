module Party
  class VotesController < Party::BaseController
    def create
      unless current_party_member
        redirect_to party_board_path(token: @board.share_token), alert: "Choose who you are before voting."
        return
      end

      poll = @board.polls.open.find(params[:poll_id])
      option = poll.options.find(params.require(:option_id))

      vote = poll.votes.find_or_initialize_by(party_member_id: current_party_member.id)
      vote.assign_attributes(
        party_poll_option: option,
        wedding_id: current_wedding.id
      )

      if vote.save
        redirect_to party_board_path(token: @board.share_token), notice: "Vote saved."
      else
        redirect_to party_board_path(token: @board.share_token), alert: vote.errors.full_messages.to_sentence
      end
    end
  end
end

module Admin
  class PartyController < Admin::BaseController
    def show
      @boards = PartyBoard.ensure_for!(current_wedding)
      @boards.each { |board| PartyBoards::SyncFromWeddingParty.call(board: board) if board.members.none? }
      @boards = current_wedding.party_boards.ordered.includes(:members, :polls)
    end
  end
end

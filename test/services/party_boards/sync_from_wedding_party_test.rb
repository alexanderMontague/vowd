require "test_helper"

class PartyBoards::SyncFromWeddingPartyTest < ActiveSupport::TestCase
  setup do
    @wedding = create_wedding(
      wedding_party: {
        "bridesmaids" => [{ "name" => "Nora", "role" => "Maid of Honour" }],
        "groomsmen" => [{ "name" => "Sam", "role" => "Best Man" }, { "name" => "", "role" => "Skip" }]
      }
    )
    @board = PartyBoard.create!(wedding_id: @wedding.id, kind: "bachelor")
  end

  test "imports named groomsmen only" do
    PartyBoards::SyncFromWeddingParty.call(board: @board)

    assert_equal ["Sam"], @board.members.ordered.map(&:name)
    assert_equal ["Best Man"], @board.members.ordered.map(&:role)
    assert_equal ["wedding_party"], @board.members.map(&:source).uniq
  end

  test "sync is idempotent for wedding party keys" do
    PartyBoards::SyncFromWeddingParty.call(board: @board)
    assert_no_difference("PartyMember.count") do
      PartyBoards::SyncFromWeddingParty.call(board: @board)
    end
  end
end

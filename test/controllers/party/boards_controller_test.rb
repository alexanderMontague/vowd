require "test_helper"

class Party::BoardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @wedding = create_wedding(
      wedding_party: {
        "bridesmaids" => [],
        "groomsmen" => [{ "name" => "Sam", "role" => "Best Man" }]
      }
    )
    host_wedding!(@wedding)
    @board = PartyBoard.ensure_for!(@wedding).find { |b| b.kind == "bachelor" }
    PartyBoards::SyncFromWeddingParty.call(board: @board)
    @member = @board.members.first
    @poll = @board.polls.create!(wedding_id: @wedding.id, title: "Destination?")
    @option_a = @poll.options.create!(wedding_id: @wedding.id, title: "Nashville", price_text: "$400")
    @option_b = @poll.options.create!(wedding_id: @wedding.id, title: "Austin", price_text: "$350")
  end

  test "share link shows itinerary ideas and polls" do
    @board.ideas.create!(wedding_id: @wedding.id, title: "Keep it low key")
    @board.itinerary_items.create!(wedding_id: @wedding.id, title: "Dinner", location: "Main St")

    get party_board_path(token: @board.share_token)

    assert_response :success
    assert_select "h1", text: @board.title
    assert_match "Keep it low key", response.body
    assert_match "Dinner", response.body
    assert_match "Destination?", response.body
  end

  test "invalid token is not found" do
    get party_board_path(token: "nope")

    assert_response :not_found
  end

  test "identify remembers member and allows voting" do
    post party_identify_path(token: @board.share_token), params: { member_id: @member.id }
    assert_redirected_to party_board_path(token: @board.share_token)

    assert_difference("PartyPollVote.count", 1) do
      post party_vote_path(token: @board.share_token, poll_id: @poll.id),
           params: { option_id: @option_a.id }
    end
    assert_redirected_to party_board_path(token: @board.share_token)
    assert_equal @option_a.id, @poll.votes.find_by!(party_member_id: @member.id).party_poll_option_id

    assert_no_difference("PartyPollVote.count") do
      post party_vote_path(token: @board.share_token, poll_id: @poll.id),
           params: { option_id: @option_b.id }
    end
    assert_equal @option_b.id, @poll.votes.find_by!(party_member_id: @member.id).party_poll_option_id
  end

  test "voting without identity is rejected" do
    assert_no_difference("PartyPollVote.count") do
      post party_vote_path(token: @board.share_token, poll_id: @poll.id),
           params: { option_id: @option_a.id }
    end
    assert_redirected_to party_board_path(token: @board.share_token)
  end

  test "old token stops working after regenerate" do
    old_token = @board.share_token
    @board.regenerate_share_token!

    get party_board_path(token: old_token)
    assert_response :not_found

    get party_board_path(token: @board.reload.share_token)
    assert_response :success
  end

  test "token from another wedding does not leak on this host" do
    other = create_wedding
    other_board = PartyBoard.ensure_for!(other).first

    get party_board_path(token: other_board.share_token)
    assert_response :not_found
  end
end

require "test_helper"

class Admin::PartyControllerTest < ActionDispatch::IntegrationTest
  setup do
    @wedding = create_wedding(
      wedding_party: {
        "title" => "Wedding Party",
        "subtitle" => "",
        "bridesmaids_title" => "Bridesmaids",
        "groomsmen_title" => "Groomsmen",
        "bridesmaids" => [{ "name" => "Nora", "role" => "Maid of Honour" }],
        "groomsmen" => [{ "name" => "Sam", "role" => "Best Man" }]
      }
    )
    @admin = create_admin_for(@wedding)
    sign_in_admin(@admin)
  end

  test "hub ensures boards and seeds wedding party members" do
    assert_difference("PartyBoard.count", 2) do
      get admin_party_path
    end

    assert_response :success
    assert_select "h1", text: "Party planning"
    assert_select "a[href=?]", admin_party_board_path(kind: "bachelor")
    assert_select "a[href=?]", admin_party_board_path(kind: "bachelorette")

    bachelor = @wedding.party_boards.find_by!(kind: "bachelor")
    bachelorette = @wedding.party_boards.find_by!(kind: "bachelorette")
    assert_equal ["Sam"], bachelor.members.ordered.map(&:name)
    assert_equal ["Nora"], bachelorette.members.ordered.map(&:name)
  end

  test "board show renders share link and sections" do
    board = PartyBoard.ensure_for!(@wedding).find { |b| b.kind == "bachelor" }
    PartyBoards::SyncFromWeddingParty.call(board: board)

    get admin_party_board_path(kind: "bachelor")

    assert_response :success
    assert_select "input[value=?]", "#{request.base_url}#{board.share_path}"
    assert_select "h2", text: "People"
    assert_select "h2", text: "Ideas"
    assert_select "h2", text: "Itinerary"
    assert_select "h2", text: "Polls"
  end

  test "can add custom member idea itinerary and poll" do
    PartyBoard.ensure_for!(@wedding)

    assert_difference("PartyMember.count", 1) do
      post admin_party_board_members_path("bachelor"),
           params: { party_member: { name: "Chris", role: "Friend" } }
    end
    assert_redirected_to admin_party_board_path(kind: "bachelor")

    assert_difference("PartyIdea.count", 1) do
      post admin_party_board_ideas_path("bachelor"),
           params: { party_idea: { title: "Cabin weekend", body: "Maybe June" } }
    end

    assert_difference("PartyItineraryItem.count", 1) do
      post admin_party_board_itinerary_items_path("bachelor"),
           params: {
             party_itinerary_item: {
               title: "Welcome drinks",
               location: "Downtown",
               starts_at_text: "7:00 PM"
             }
           }
    end

    assert_difference("PartyPoll.count", 1) do
      post admin_party_board_polls_path("bachelor"),
           params: { party_poll: { title: "Where should we go?" } }
    end

    poll = @wedding.party_boards.find_by!(kind: "bachelor").polls.last
    assert_difference("PartyPollOption.count", 1) do
      post admin_party_board_poll_options_path("bachelor", poll),
           params: { party_poll_option: { title: "Nashville", price_text: "~$400" } }
    end
  end

  test "regenerate token rotates share link" do
    board = PartyBoard.ensure_for!(@wedding).find { |b| b.kind == "bachelor" }
    old_token = board.share_token

    post regenerate_token_admin_party_board_path(kind: "bachelor")

    assert_redirected_to admin_party_board_path(kind: "bachelor")
    refute_equal old_token, board.reload.share_token
  end

  test "cannot access another wedding party board" do
    other = create_wedding
    other_board = PartyBoard.ensure_for!(other).first
    PartyMember.create!(
      party_board: other_board,
      wedding_id: other.id,
      name: "Leak",
      source: "custom"
    )

    get admin_party_board_path(kind: other_board.kind)
    assert_response :success
    assert_select "td", text: "Leak", count: 0
  end
end

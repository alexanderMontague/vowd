require "test_helper"

class RSVPServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @wedding = Wedding.current
    @household = Household.create!(wedding_id: @wedding.id, name: "Test Household")
    @accepting_guest = Guest.create!(
      wedding_id: @wedding.id, household: @household,
      first_name: "Ada", last_name: "Lovelace", email: "ada@example.com"
    )
    @declining_guest = Guest.create!(
      wedding_id: @wedding.id, household: @household,
      first_name: "Alan", last_name: "Turing", email: "alan@example.com"
    )
  end

  test "persists per-guest song request and notes" do
    result = RSVPService.submit!(household: @household, rsvp_params: {
      @accepting_guest.id => {
        status: "accepted",
        meal_choice: "Chicken",
        dietary_restrictions: "None",
        song_request: "Dancing Queen",
        notes: "So excited!"
      }
    })

    assert result[:success]
    rsvp = @accepting_guest.rsvp.reload
    assert_equal "accepted", rsvp.status
    assert_equal "Dancing Queen", rsvp.song_request
    assert_equal "So excited!", rsvp.notes
  end

  test "clears meal choice when declining but keeps song request and notes" do
    result = RSVPService.submit!(household: @household, rsvp_params: {
      @declining_guest.id => {
        status: "declined",
        meal_choice: "Beef",
        dietary_restrictions: "Vegan",
        song_request: "Bohemian Rhapsody",
        notes: "Wish we could make it."
      }
    })

    assert result[:success]
    rsvp = @declining_guest.rsvp.reload
    assert_equal "declined", rsvp.status
    assert_nil rsvp.meal_choice
    assert_equal "Bohemian Rhapsody", rsvp.song_request
    assert_equal "Wish we could make it.", rsvp.notes
  end

  test "updates every guest in the household within a single submission" do
    RSVPService.submit!(household: @household, rsvp_params: {
      @accepting_guest.id => { status: "accepted", song_request: "September" },
      @declining_guest.id => { status: "declined", notes: "Next time!" }
    })

    assert_equal "September", @accepting_guest.rsvp.reload.song_request
    assert_equal "Next time!", @declining_guest.rsvp.reload.notes
  end

  test "enqueues the confirmation job on success" do
    assert_enqueued_with(job: RSVPConfirmationJob, args: [@household.id]) do
      RSVPService.submit!(household: @household, rsvp_params: {
        @accepting_guest.id => { status: "accepted" }
      })
    end
  end

  test "rolls back and reports failure on an invalid status" do
    result = RSVPService.submit!(household: @household, rsvp_params: {
      @accepting_guest.id => { status: "maybe", song_request: "Should Not Save" }
    })

    assert_not result[:success]
    assert_nil @accepting_guest.rsvp.reload.song_request
  end
end

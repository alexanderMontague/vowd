require "test_helper"

module Public
  class RsvpsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      host_wedding!(@wedding)
      @rsvp_flag = WeddingMetadata.create!(wedding_id: @wedding.id, key: "rsvp_visible", value: "true")
      @household = Household.create!(wedding_id: @wedding.id, name: "Public Household")
      @guest = Guest.create!(
        wedding_id: @wedding.id, household: @household,
        first_name: "Grace", last_name: "Hopper", email: "grace@example.com"
      )
    end

    teardown do
      @rsvp_flag&.destroy
    end

    test "edit renders the song request field" do
      get public_rsvp_path(@guest.invite_code)
      assert_response :success
      assert_includes response.body, "Song Request"
      assert_includes response.body, "song_request"
    end

    test "update persists song request and message then redirects to thanks" do
      patch public_rsvp_path(@guest.invite_code), params: {
        rsvps: {
          @guest.id.to_s => {
            status: "accepted",
            song_request: "Livin' on a Prayer",
            notes: "Can't wait to celebrate with you!"
          }
        }
      }

      assert_redirected_to public_rsvp_thanks_path(@guest.invite_code)
      rsvp = @guest.rsvp.reload
      assert_equal "Livin' on a Prayer", rsvp.song_request
      assert_equal "Can't wait to celebrate with you!", rsvp.notes
    end

    test "update is blocked when rsvps are closed" do
      @rsvp_flag.update!(value: "false")

      patch public_rsvp_path(@guest.invite_code), params: {
        rsvps: { @guest.id.to_s => { status: "accepted", song_request: "No Save" } }
      }

      assert_response :not_found
      assert_nil @guest.rsvp.reload.song_request
    end
  end
end

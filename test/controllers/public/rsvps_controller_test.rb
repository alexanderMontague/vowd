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

    test "lookup renders the framed portrait and floating photos when placed" do
      portrait = create_asset(alt: "Us at sunset")
      floating = Array.new(3) { create_asset }
      @wedding.update!(
        placements: {
          "rsvp_portrait" => [portrait.id],
          "rsvp_floating" => floating.map(&:id)
        }
      )

      get public_rsvp_lookup_path

      assert_response :success
      assert_select ".framed-photo img.framed-photo__image[alt='Us at sunset']"
      assert_select "[data-controller=parallax] .floating-photo", 3
      assert_select ".botanical-accent"
    end

    test "lookup omits photo compositions when no slots are placed" do
      get public_rsvp_lookup_path

      assert_response :success
      assert_select ".framed-photo", false
      assert_select ".floating-photos", false
      assert_select ".botanical-accent"
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

    test "an invite code from another wedding is not found on this host" do
      other_wedding = create_wedding
      other_flag = WeddingMetadata.create!(wedding_id: other_wedding.id, key: "rsvp_visible", value: "true")
      other_household = Household.create!(wedding_id: other_wedding.id, name: "Other Household")
      other_guest = Guest.create!(
        household: other_household, first_name: "Ada", last_name: "Lovelace"
      )

      get public_rsvp_path(other_guest.invite_code)
      assert_response :not_found

      patch public_rsvp_path(other_guest.invite_code), params: {
        rsvps: { other_guest.id.to_s => { status: "accepted" } }
      }
      assert_response :not_found
      assert_equal "pending", other_guest.rsvp.reload.status
    ensure
      other_flag&.destroy
    end

    test "update is blocked when rsvps are closed" do
      @rsvp_flag.update!(value: "false")

      patch public_rsvp_path(@guest.invite_code), params: {
        rsvps: { @guest.id.to_s => { status: "accepted", song_request: "No Save" } }
      }

      assert_response :not_found
      assert_nil @guest.rsvp.reload.song_request
    end

    private

    def create_asset(attrs = {})
      @wedding.wedding_assets.create!(
        {
          object_key: "#{Rails.env}/#{@wedding.id}/site/photos/#{SecureRandom.hex(6)}.webp",
          content_type: "image/webp",
          byte_size: 2048
        }.merge(attrs)
      )
    end
  end
end

require "test_helper"

module Admin
  class GuestsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      @admin = create_admin_for(@wedding)
      @household = Household.create!(wedding_id: @wedding.id, name: "Montague")
      @guest = Guest.create!(
        wedding_id: @wedding.id,
        household: @household,
        first_name: "Alex",
        last_name: "Montague",
        email: "alex@example.com",
        phone_number: "555-0100"
      )
      sign_in_admin(@admin)
    end

    test "index lists guests for the current wedding" do
      get admin_guests_path

      assert_response :success
      assert_includes response.body, "Alex Montague"
    end

    test "index filters by household" do
      other = Household.create!(wedding_id: @wedding.id, name: "Other")
      Guest.create!(
        wedding_id: @wedding.id, household: other,
        first_name: "Other", last_name: "Guest", email: "other@example.com"
      )

      get admin_guests_path, params: { household_id: @household.id }

      assert_response :success
      assert_includes response.body, "Alex Montague"
      assert_not_includes response.body, "Other Guest"
    end

    test "index filters by rsvp status" do
      @guest.rsvp.update!(status: "accepted")
      pending = Guest.create!(
        wedding_id: @wedding.id, household: @household,
        first_name: "Pending", last_name: "Guest", email: "pending@example.com"
      )

      get admin_guests_path, params: { rsvp_status: "accepted" }

      assert_response :success
      assert_includes response.body, "Alex Montague"
      assert_not_includes response.body, pending.full_name
    end

    test "index does not leak guests from other weddings" do
      other_wedding = create_wedding
      other_household = Household.create!(wedding_id: other_wedding.id, name: "Leak")
      Guest.create!(
        wedding_id: other_wedding.id, household: other_household,
        first_name: "Secret", last_name: "Guest", email: "secret@example.com"
      )

      get admin_guests_path

      assert_not_includes response.body, "Secret Guest"
    end

    test "new redirects to household form" do
      get new_admin_guest_path

      assert_redirected_to new_admin_household_path
    end

    test "create redirects to household form" do
      post admin_guests_path, params: { guest: { first_name: "Nope" } }

      assert_redirected_to new_admin_household_path
    end

    test "show redirects to edit" do
      get admin_guest_path(@guest)

      assert_redirected_to edit_admin_guest_path(@guest)
    end

    test "edit renders the guest form" do
      get edit_admin_guest_path(@guest)

      assert_response :success
      assert_select "form[action=?]", admin_guest_path(@guest)
    end

    test "update changes guest details" do
      patch admin_guest_path(@guest), params: {
        guest: { first_name: "Alexander", email: "alexander@example.com" }
      }

      assert_redirected_to admin_guests_path
      @guest.reload
      assert_equal "Alexander", @guest.first_name
      assert_equal "alexander@example.com", @guest.email
    end

    test "update with invalid data re-renders edit" do
      patch admin_guest_path(@guest), params: {
        guest: { first_name: "", email: "not-an-email" }
      }

      assert_response :unprocessable_content
      assert_equal "Alex", @guest.reload.first_name
    end

    test "update cannot move a guest into another wedding household" do
      other_wedding = create_wedding
      other_household = Household.create!(wedding_id: other_wedding.id, name: "Foreign")

      patch admin_guest_path(@guest), params: {
        guest: { household_id: other_household.id }
      }

      assert_response :unprocessable_content
      assert_equal @household.id, @guest.reload.household_id
    end

    test "destroy removes a guest and their rsvp" do
      assert_difference("Guest.count", -1) do
        assert_difference("RSVP.count", -1) do
          delete admin_guest_path(@guest)
        end
      end

      assert_redirected_to admin_guests_path
    end

    test "destroy unlinks a matched save the date signup" do
      signup = SaveTheDateSignup.create!(
        wedding_id: @wedding.id,
        email: "alex@example.com",
        guest: @guest,
        matched_at: Time.current
      )

      assert_difference("Guest.count", -1) do
        assert_no_difference("SaveTheDateSignup.count") do
          delete admin_guest_path(@guest)
        end
      end

      signup.reload
      assert_nil signup.guest_id
      assert_nil signup.matched_at
      assert_redirected_to admin_guests_path
    end

    test "destroy removes invitations and notification deliveries" do
      Invitation.create!(guest: @guest, status: "sent", sent_at: Time.current)
      NotificationDelivery.create!(
        guest: @guest,
        wedding_id: @wedding.id,
        reminder_key: "week_before",
        channel: "email",
        scheduled_for: Date.current,
        status: "queued"
      )

      assert_difference("Invitation.count", -1) do
        assert_difference("NotificationDelivery.count", -1) do
          delete admin_guest_path(@guest)
        end
      end
    end

    test "destroy nullifies disposable photo attribution" do
      photo = DisposablePhoto.create!(
        wedding_id: @wedding.id,
        guest: @guest,
        object_key: "test/#{SecureRandom.hex(8)}.jpg",
        content_type: "image/jpeg",
        byte_size: 2048,
        flash_enabled: false,
        captured_at: Time.current
      )

      DisposableCamera::StorageClient.stub(:delete!, true) do
        assert_no_difference("DisposablePhoto.count") do
          delete admin_guest_path(@guest)
        end
      end

      assert_nil photo.reload.guest_id
    end

    test "destroy does not allow deleting another wedding's guest" do
      other_wedding = create_wedding
      other_household = Household.create!(wedding_id: other_wedding.id, name: "Other")
      other_guest = Guest.create!(
        wedding_id: other_wedding.id, household: other_household,
        first_name: "Other", last_name: "Person", email: "other@example.com"
      )

      assert_no_difference("Guest.count") do
        delete admin_guest_path(other_guest)
      end

      assert_response :not_found
    end

    test "export downloads a csv of guests" do
      get export_admin_guests_path(format: :csv)

      assert_response :success
      assert_equal "text/csv", response.media_type
      assert_includes response.body, "Alex"
      assert_includes response.body, "Montague"
    end
  end
end

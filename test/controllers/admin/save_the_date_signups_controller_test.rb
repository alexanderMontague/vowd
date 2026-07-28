require "test_helper"

module Admin
  class SaveTheDateSignupsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      @admin = create_admin_for(@wedding)
      @household = Household.create!(wedding_id: @wedding.id, name: "Admin Household")
      @guest = Guest.create!(
        wedding_id: @wedding.id, household: @household,
        first_name: "Casey", last_name: "Doe", email: "casey@example.com"
      )
      @signup = SaveTheDateSignup.create!(wedding_id: @wedding.id, email: "guest@example.com")

      sign_in_admin(@admin)
    end

    test "index lists signups for the current wedding" do
      get admin_save_the_date_signups_path
      assert_response :success
      assert_includes response.body, "guest@example.com"
    end

    test "index does not leak signups from other weddings" do
      SaveTheDateSignup.create!(wedding_id: "other-wedding", email: "leak@example.com")
      get admin_save_the_date_signups_path
      assert_not_includes response.body, "leak@example.com"
    end

    test "index only offers unmatched guests in the match dropdown" do
      other_guest = Guest.create!(
        wedding_id: @wedding.id, household: @household,
        first_name: "Taken", last_name: "Guest", email: "taken@example.com"
      )
      SaveTheDateSignup.create!(wedding_id: @wedding.id, email: "already@example.com",
                                guest: other_guest, matched_at: Time.current)

      get admin_save_the_date_signups_path

      assert_select "select[name='guest_id'] option", text: /Casey Doe/
      assert_select "select[name='guest_id'] option", text: /Taken Guest/, count: 0
    end

    test "match links a signup to a guest and backfills contact info" do
      patch match_admin_save_the_date_signup_path(@signup), params: { guest_id: @guest.id }

      assert_redirected_to admin_save_the_date_signups_path
      @signup.reload
      assert_equal @guest.id, @signup.guest_id
      assert_not_nil @signup.matched_at
    end

    test "unmatch clears the association" do
      @signup.update!(guest: @guest, matched_at: Time.current)

      delete unmatch_admin_save_the_date_signup_path(@signup)

      assert_redirected_to admin_save_the_date_signups_path
      assert_nil @signup.reload.guest_id
    end

    test "destroy removes the signup" do
      assert_difference("SaveTheDateSignup.count", -1) do
        delete admin_save_the_date_signup_path(@signup)
      end
      assert_redirected_to admin_save_the_date_signups_path
    end

    test "destroy removes a matched signup without deleting the guest" do
      @signup.update!(guest: @guest, matched_at: Time.current)

      assert_difference("SaveTheDateSignup.count", -1) do
        assert_no_difference("Guest.count") do
          delete admin_save_the_date_signup_path(@signup)
        end
      end

      assert Guest.exists?(@guest.id)
    end

    test "match rejects a guest from another wedding" do
      other_wedding = create_wedding
      other_household = Household.create!(wedding_id: other_wedding.id, name: "Other")
      other_guest = Guest.create!(
        wedding_id: other_wedding.id, household: other_household,
        first_name: "Other", last_name: "Person", email: "other@example.com"
      )

      patch match_admin_save_the_date_signup_path(@signup), params: { guest_id: other_guest.id }

      assert_redirected_to admin_save_the_date_signups_path
      assert_nil @signup.reload.guest_id
    end

    test "match without a guest_id redirects with an alert" do
      patch match_admin_save_the_date_signup_path(@signup)

      assert_redirected_to admin_save_the_date_signups_path
      assert_equal "Please choose a guest to match.", flash[:alert]
    end

    test "unmatch and destroy are scoped to the current wedding" do
      other_wedding = create_wedding
      other = SaveTheDateSignup.create!(wedding_id: other_wedding.id, email: "other@example.com")

      delete unmatch_admin_save_the_date_signup_path(other)
      assert_response :not_found

      delete admin_save_the_date_signup_path(other)
      assert_response :not_found
      assert SaveTheDateSignup.exists?(other.id)
    end

    test "index filters matched and unmatched signups" do
      matched = SaveTheDateSignup.create!(
        wedding_id: @wedding.id, email: "matched@example.com",
        guest: @guest, matched_at: Time.current
      )

      get admin_save_the_date_signups_path, params: { status: "matched" }
      assert_response :success
      assert_includes response.body, matched.email
      assert_not_includes response.body, @signup.email

      get admin_save_the_date_signups_path, params: { status: "unmatched" }
      assert_response :success
      assert_includes response.body, @signup.email
      assert_not_includes response.body, matched.email
    end
  end
end

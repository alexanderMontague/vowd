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
  end
end

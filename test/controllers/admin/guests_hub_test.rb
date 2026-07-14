require "test_helper"

module Admin
  class GuestsHubTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      @admin = create_admin_for(@wedding)
      sign_in_admin(@admin)
    end

    test "guests index renders hub tabs" do
      get admin_guests_path

      assert_response :success
      assert_includes response.body, "admin-hub-nav"
      assert_includes response.body, "Invitations"
      assert_includes response.body, "Save the Date"
      assert_includes response.body, "Add household"
    end

    test "sidebar shows a single Guests item" do
      get admin_guests_path

      assert_response :success
      assert_includes response.body, ">Guests<"
      refute_includes response.body, ">Households<"
      refute_includes response.body, ">Guest list<"
    end

    test "invitations and save the date pages include hub nav" do
      get admin_invitations_path
      assert_response :success
      assert_includes response.body, "admin-hub-nav"

      get admin_save_the_date_signups_path
      assert_response :success
      assert_includes response.body, "admin-hub-nav"
    end

    test "households index redirects into guests list" do
      get admin_households_path

      assert_redirected_to admin_guests_path
    end
  end
end

require "test_helper"

module Admin
  class InvitationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      @admin = create_admin_for(@wedding)
      @household = Household.create!(wedding_id: @wedding.id, name: "Montague")
      Guest.create!(household: @household, first_name: "Alex", last_name: "Guest", email: "alex@example.com")
      sign_in_admin(@admin)
    end

    test "email invitations page spaces stats from the table" do
      get admin_invitations_path

      assert_response :success
      assert_select ".stats-grid"
      assert_select ".admin-editor-divider"
      assert_select ".table-container"
    end

    test "physical invitations page renders themed panels and aligned controls" do
      get physical_admin_invitations_path, params: { household_id: @household.id }

      assert_response :success
      assert_select ".invitation-controls"
      assert_select ".invitation-panel", minimum: 1
      assert_select ".invitation-panel[style*='--theme-ink']"
      assert_includes response.body, "data-theme-fonts"
    end
  end
end

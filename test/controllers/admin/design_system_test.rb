require "test_helper"

class Admin::DesignSystemTest < ActionDispatch::IntegrationTest
  setup do
    @wedding = create_wedding
    @admin = create_admin_for(@wedding)
    sign_in_admin(@admin)
  end

  test "guests page uses shared page header and hub chips" do
    get admin_guests_path

    assert_response :success
    assert_select "body.admin-app"
    assert_select ".admin-hub-nav"
    assert_select ".admin-page-header h1", text: "Guests"
    assert_select ".admin-page-header__actions a", text: "Add household"
  end

  test "party hub uses shared page header" do
    get admin_party_path

    assert_response :success
    assert_select ".admin-page-header h1", text: "Party planning"
    assert_select ".admin-hub-nav a", text: "Overview"
  end

  test "settings uses shared page header" do
    get admin_settings_path

    assert_response :success
    assert_select ".admin-page-header h1", text: "Feature flags"
  end

  test "compiled admin stylesheet is present" do
    css_path = Rails.root.join("app/assets/tailwind/admin.css")
    assert File.exist?(css_path), "expected admin.css design system sheet"

    contents = File.read(css_path)
    assert_includes contents, "--admin-ink"
    assert_includes contents, "--admin-accent"
    assert_includes contents, "--admin-font"
    assert_includes contents, "Plus Jakarta Sans"
    assert_includes contents, ".admin-app .admin-side-nav"
  end
end

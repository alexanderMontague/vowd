require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @wedding = create_wedding
    @admin = create_admin_for(@wedding)
    sign_in_admin(@admin)
  end

  test "dashboard shows save the date responses metric" do
    SaveTheDateSignup.create!(wedding_id: @wedding.id, email: "one@example.com", name: "One")
    SaveTheDateSignup.create!(wedding_id: @wedding.id, email: "two@example.com", name: "Two")

    get admin_root_path

    assert_response :success
    assert_select "body.admin-app"
    assert_select ".admin-section__label", text: "RSVPs"
    assert_select ".admin-section__label", text: "Outreach"
    assert_select ".stat-label", text: "Save the Date"
    assert_select "a.stat-card--link[href=?]", admin_save_the_date_signups_path
    assert_match "2", response.body
  end

  test "admin nav puts dashboard first and groups wedding with theme" do
    get admin_root_path

    assert_response :success
    assert_select ".admin-side-nav-links" do
      assert_select ".admin-side-nav-section", text: "Website"
      assert_select ".admin-side-nav-section", text: "Planning"
      assert_select "a[href=?]", admin_party_path, text: "Party planning"
    end
    assert_select ".admin-topbar-toggle"
  end

  test "admin shell uses the dedicated design system" do
    get admin_root_path

    assert_response :success
    assert_select "body.admin-app"
    assert_select ".admin-page-header h1", text: "Dashboard"
    assert_select ".admin-stack"
    assert_select ".admin-section__label", text: "Upcoming events"
  end
end

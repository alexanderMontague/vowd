require "test_helper"

module Platform
  class HomesControllerTest < ActionDispatch::IntegrationTest
    setup do
      host_platform!
    end

    test "landing page returns success" do
      get platform_root_path

      assert_response :success
    end

    test "landing page uses platform hero branding and product features" do
      get platform_root_path

      assert_response :success
      assert_select ".platform-app"
      assert_select ".platform-hero__brand", text: "Vowd"
      assert_select ".platform-hero__actions a", text: "Create your site"
      assert_select ".platform-feature h3", text: "Theme editor"
      assert_select ".platform-feature h3", text: "Disposable camera"
      assert_select "img[src*='marketing/hero']"
      assert_select "img[src*='marketing/theme']"
      assert_select "img[src*='marketing/admin']"
    end
  end
end


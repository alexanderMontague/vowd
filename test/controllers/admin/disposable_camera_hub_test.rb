require "test_helper"

module Admin
  class DisposableCameraHubTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      @admin = create_admin_for(@wedding)
      sign_in_admin(@admin)
    end

    test "sidebar shows a single Disposable camera item" do
      get admin_disposable_photos_path

      assert_response :success
      assert_includes response.body, ">Disposable camera<"
      refute_includes response.body, ">Photos<"
      refute_includes response.body, ">Camera sign<"
    end

    test "gallery and sign pages include hub tabs" do
      get admin_disposable_photos_path
      assert_response :success
      assert_includes response.body, "admin-hub-nav"
      assert_includes response.body, ">Gallery<"
      assert_includes response.body, ">Sign<"
      assert_includes response.body, "Gallery"

      get admin_dispo_sign_path
      assert_response :success
      assert_includes response.body, "admin-hub-nav"
      assert_includes response.body, ">Sign<"
    end
  end
end

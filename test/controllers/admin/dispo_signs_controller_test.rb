require "test_helper"

module Admin
  class DispoSignsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding(id: "sign-admin-wedding")
      @admin = create_admin_for(@wedding)
      sign_in_admin(@admin)
    end

    test "show renders the printable sign with the wedding's dispo url" do
      get admin_dispo_sign_path

      assert_response :success
      assert_includes response.body, "http://sign-admin-wedding.example.test:3003/dispo"
      assert_includes response.body, "sign-print-sheet"
      assert_includes response.body, "<svg"
    end

    test "png download is sent as an attachment named for the wedding" do
      get admin_dispo_sign_path(format: :png)

      assert_response :success
      assert_equal "image/png", response.media_type
      assert_match(/attachment/, response.headers["Content-Disposition"])
      assert_match(/dispo-qr-sign-admin-wedding\.png/, response.headers["Content-Disposition"])
      assert_equal [137, 80, 78, 71].pack("C*"), response.body.byteslice(0, 4)
    end

    test "svg download is sent as an attachment named for the wedding" do
      get admin_dispo_sign_path(format: :svg)

      assert_response :success
      assert_equal "image/svg+xml", response.media_type
      assert_match(/dispo-qr-sign-admin-wedding\.svg/, response.headers["Content-Disposition"])
      assert_includes response.body, "<svg"
    end

    test "the sign is unreachable without an admin session" do
      delete admin_logout_path
      get admin_dispo_sign_path

      assert_redirected_to admin_login_path
    end

    test "each wedding's admin sees only its own code target" do
      other_wedding = create_wedding(id: "other-sign-wedding")
      other_admin = create_admin_for(other_wedding)
      sign_in_admin(other_admin)

      get admin_dispo_sign_path

      assert_response :success
      assert_includes response.body, "http://other-sign-wedding.example.test:3003/dispo"
      assert_not_includes response.body, "http://sign-admin-wedding.example.test:3003/dispo"
    end
  end
end

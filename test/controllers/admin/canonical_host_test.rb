require "test_helper"

module Admin
  class CanonicalHostTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding(id: "acme-wedding", custom_domain: "acme.example.com")
      @admin = create_admin_for(@wedding)
    end

    test "admin login on custom domain redirects to slug subdomain" do
      host! @wedding.custom_domain
      get admin_login_path

      assert_response :temporary_redirect
      assert_redirected_to AppHost.wedding_admin_url(@wedding, path: "/admin/login")
    end

    test "admin root on custom domain redirects to slug subdomain" do
      host! @wedding.custom_domain
      get admin_root_path

      assert_response :temporary_redirect
      assert_redirected_to AppHost.wedding_admin_url(@wedding, path: "/admin")
    end

    test "admin login on slug subdomain does not redirect" do
      host_wedding!(@wedding)
      get admin_login_path

      assert_response :success
    end

    test "login works on slug subdomain after custom domain redirect target" do
      host_wedding!(@wedding)
      post admin_login_path, params: { email: @admin.email, password: "password" }

      assert_redirected_to admin_root_path
      assert_equal @admin.id, session[:admin_id]
    end
  end
end

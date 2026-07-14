require "test_helper"

module Admin
  class TenantIsolationTest < ActionDispatch::IntegrationTest
    setup do
      @wedding_a = create_wedding(id: "wedding-a")
      @wedding_b = create_wedding(id: "wedding-b")
      @admin_a = create_admin_for(@wedding_a, email: "admin-a@example.com")
      @admin_b = create_admin_for(@wedding_b, email: "admin-b@example.com")
    end

    test "admin for wedding A cannot log in on wedding B host" do
      host_wedding!(@wedding_b)
      post admin_login_path, params: { email: @admin_a.email, password: "password" }

      assert_response :unprocessable_content
      assert_nil session[:admin_id]
    end

    test "admin for wedding A cannot access wedding B settings" do
      host_wedding!(@wedding_b)
      post admin_login_path, params: { email: @admin_b.email, password: "password" }
      assert_equal @admin_b.id, session[:admin_id]

      # Session cookies are host-scoped in integration tests, so authenticate on B's
      # host then resolve the session id to wedding A's admin to hit ownership checks.
      AdminUser.stub(:find_by, ->(**kwargs) { kwargs[:id].present? ? @admin_a : nil }) do
        get admin_settings_path
      end

      assert_redirected_to admin_login_path
      assert_nil session[:admin_id]
      assert_equal "You do not have access to this wedding", flash[:alert]
    end
  end
end

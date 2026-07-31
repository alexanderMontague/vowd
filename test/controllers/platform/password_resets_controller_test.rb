require "test_helper"

module Platform
  class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
    setup do
      host_platform!
      @wedding = create_wedding(id: "reset-wedding")
      @admin = create_admin_for(@wedding, email: "reset@example.com")
    end

    test "new renders forgot password form" do
      get platform_forgot_password_path

      assert_response :success
      assert_select "form[action='#{platform_forgot_password_path}']"
    end

    test "create sends mail for known email and always shows the same notice" do
      assert_emails 1 do
        post platform_forgot_password_path, params: { email: "reset@example.com" }
      end

      assert_redirected_to platform_login_path
      follow_redirect!
      assert_match(/If that email is on file/, response.body)
    end

    test "create does not reveal unknown emails" do
      assert_no_emails do
        post platform_forgot_password_path, params: { email: "nobody@example.com" }
      end

      assert_redirected_to platform_login_path
    end

    test "edit and update reset the password and sign in" do
      token = @admin.generate_token_for(:password_reset)

      get platform_reset_password_path(token: token)
      assert_response :success

      patch platform_reset_password_path(token: token), params: {
        password: "new-password",
        password_confirmation: "new-password"
      }

      assert_redirected_to AppHost.wedding_admin_url(@wedding)
      assert_equal @admin.id, session[:admin_id]
      assert @admin.reload.authenticate("new-password")
    end

    test "edit rejects expired or invalid tokens" do
      get platform_reset_password_path(token: "not-a-real-token")

      assert_redirected_to platform_forgot_password_path
    end
  end
end

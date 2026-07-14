require "test_helper"

module Platform
  class RegistrationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      host_platform!
    end

    test "new renders signup form" do
      get platform_signup_path

      assert_response :success
      assert_select "form[action='#{platform_signup_path}'][data-turbo='false']"
    end

    test "create registers a wedding and redirects to admin" do
      assert_difference(["Wedding.count", "AdminUser.count"], 1) do
        post platform_signup_path, params: {
          email: "signup@example.com",
          password: "password",
          password_confirmation: "password",
          slug: "britt-and-alex",
          title: "Britt & Alex",
          partner1: "Britt",
          partner2: "Alex"
        }
      end

      wedding = Wedding.find("britt-and-alex")
      assert_redirected_to AppHost.wedding_admin_url(wedding, path: "/admin/website")
      assert_equal AdminUser.find_by(email: "signup@example.com").id, session[:admin_id]
    end

    test "create with duplicate slug re-renders form" do
      create_wedding(id: "taken-slug")

      assert_no_difference(["Wedding.count", "AdminUser.count"]) do
        post platform_signup_path, params: {
          email: "other@example.com",
          password: "password",
          password_confirmation: "password",
          slug: "taken-slug",
          title: "Taken"
        }
      end

      assert_response :unprocessable_content
      assert_nil session[:admin_id]
    end
  end
end

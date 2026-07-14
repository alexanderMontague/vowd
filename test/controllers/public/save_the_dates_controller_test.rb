require "test_helper"

module Public
  class SaveTheDatesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      host_wedding!(@wedding)
    end

    test "show renders invitation video reveal" do
      get public_save_the_date_path
      assert_response :success
      assert_select "[data-controller=invitation-video]"
      assert_select %(video[data-invitation-video-target="video"][src*="britt-alex-envelope-open"])
    end

    test "show with skip_video sets Stimulus value for immediate content" do
      get public_save_the_date_path, params: { skip_video: "1" }
      assert_response :success
      assert_match(/data-invitation-video-skip-video-value="true"/, response.body)
    end

    test "show renders the contact signup form" do
      get public_save_the_date_path
      assert_response :success
      assert_select %(form[action="#{public_save_the_date_signup_path}"])
      assert_select "input[name='save_the_date_signup[email]']"
    end

    test "signup stores a contact signup and redirects with a notice" do
      assert_difference("SaveTheDateSignup.count", 1) do
        post public_save_the_date_signup_path, params: {
          save_the_date_signup: { name: "Alex", email: "alex@example.com", phone_number: "555-0101" }
        }
      end

      assert_redirected_to public_save_the_date_path(skip_video: 1)
      assert_equal "alex@example.com", SaveTheDateSignup.last.email
      assert_equal @wedding.id, SaveTheDateSignup.last.wedding_id
    end

    test "signup with invalid email redirects with an alert" do
      assert_no_difference("SaveTheDateSignup.count") do
        post public_save_the_date_signup_path, params: {
          save_the_date_signup: { email: "nope" }
        }
      end

      assert_redirected_to public_save_the_date_path(skip_video: 1)
      assert flash[:alert].present?
    end
  end
end

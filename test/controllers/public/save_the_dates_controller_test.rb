require "test_helper"

module Public
  class SaveTheDatesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      host_wedding!(@wedding)
    end

    test "show skips invitation video when none is placed" do
      get public_save_the_date_path
      assert_response :success
      assert_select "[data-controller=invitation-video]"
      assert_match(/data-invitation-video-skip-video-value="true"/, response.body)
      assert_select %(video[data-invitation-video-target="video"][src]), false
    end

    test "show renders placed invitation video" do
      asset = create_video_asset
      @wedding.update!(placements: { "invitation_envelope" => [asset.id] })

      get public_save_the_date_path
      assert_response :success
      assert_select %(video[data-invitation-video-target="video"][src*="#{asset.object_key}"])
      assert_select %(img[src*=".thumb.webp"])
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

    test "show keeps display typography for the invitation hero" do
      get public_save_the_date_path, params: { skip_video: "1" }

      assert_response :success
      assert_select "p.invitation-eyebrow", text: /Save the Date/i
      assert_select "h1.invitation-title", text: @wedding.title
      assert_select "[data-site-editor-target='hotspot']", count: 0
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

    test "show spells the elegant date and ceremony time" do
      @wedding.update!(date: Date.new(2027, 5, 10), ceremony_time: "4:30 PM")

      get public_save_the_date_path, params: { skip_video: "1" }

      assert_response :success
      assert_select ".invitation-when", text: /Monday, 10 May 2027/
      assert_select ".invitation-when", text: /four thirty in the afternoon/
    end

    test "photo compositions are absent while their slots are empty" do
      get public_save_the_date_path

      assert_response :success
      assert_select ".framed-photo", false
      assert_select ".vase-photo", false
      assert_select ".floating-photo", false
    end

    test "photo compositions render for the slots that are filled" do
      portrait = create_asset(alt: "On the pier")
      vase = create_asset
      floating = Array.new(2) { create_asset }
      @wedding.update!(
        placements: {
          "save_the_date_portrait" => [portrait.id],
          "save_the_date_vase" => [vase.id],
          "save_the_date_floating" => floating.map(&:id)
        }
      )

      get public_save_the_date_path

      assert_response :success
      assert_select ".framed-photo img.framed-photo__image[alt='On the pier']"
      assert_select ".framed-photo img.framed-photo__frame"
      assert_select ".vase-photo img.vase-photo__urn"
      assert_select %(.vase-photo img[src="#{public_site_asset_path(object_key: vase.object_key)}"])
      assert_select "[data-controller=parallax] .floating-photo", 2
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

    test "signup on a custom domain accepts a CSRF-protected POST" do
      @wedding.update!(custom_domain: "acme.example.com")
      host! @wedding.custom_domain

      ActionController::Base.allow_forgery_protection = true

      get public_save_the_date_path, params: { skip_video: "1" }
      assert_response :success

      token = css_select("input[name=authenticity_token]").first["value"]
      assert token.present?

      assert_difference("SaveTheDateSignup.count", 1) do
        post public_save_the_date_signup_path, params: {
          authenticity_token: token,
          save_the_date_signup: { name: "Alex", email: "alex@custom.test", phone_number: "" }
        }
      end

      assert_redirected_to public_save_the_date_path(skip_video: 1)
    ensure
      ActionController::Base.allow_forgery_protection = false
    end

    private

    def create_asset(attrs = {})
      @wedding.wedding_assets.create!(
        {
          object_key: "#{Rails.env}/#{@wedding.id}/site/photos/#{SecureRandom.hex(6)}.webp",
          content_type: "image/webp",
          byte_size: 2048
        }.merge(attrs)
      )
    end

    def create_video_asset(attrs = {})
      @wedding.wedding_assets.create!(
        {
          object_key: "#{Rails.env}/#{@wedding.id}/site/invitation/#{SecureRandom.hex(6)}.mp4",
          content_type: "video/mp4",
          byte_size: 4096
        }.merge(attrs)
      )
    end
  end
end

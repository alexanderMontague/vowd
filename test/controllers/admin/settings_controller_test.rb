require "test_helper"

module Admin
  class SettingsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = Wedding.current
      @admin = AdminUser.create!(
        email: "admin-#{SecureRandom.hex(4)}@example.com",
        password: "password",
        password_confirmation: "password"
      )
      sign_in_admin(@admin)
    end

    teardown do
      WeddingMetadata.where(wedding_id: @wedding.id).delete_all
    end

    test "shows settings with the current photo style selected" do
      get admin_settings_path

      assert_response :success
      assert_includes response.body, "Photo Display Style"
    end

    test "persists a valid photo style override" do
      patch admin_settings_path, params: { dispo_photo_style: "bw" }

      assert_redirected_to admin_settings_path
      Wedding.reset_current!
      assert_equal "bw", Wedding.current.dispo_photo_style
    end

    test "ignores an unknown photo style" do
      patch admin_settings_path, params: { dispo_photo_style: "polaroid" }

      assert_redirected_to admin_settings_path
      assert_nil WeddingMetadata.find_by(wedding_id: @wedding.id, key: Wedding::PHOTO_STYLE_METADATA_KEY)
    end

    test "updates photo style alongside feature flags" do
      patch admin_settings_path, params: {
        dispo_photo_style: "original",
        flags: { "rsvp_visible" => "false" }
      }

      assert_redirected_to admin_settings_path
      assert_equal "original", WeddingMetadata.find_by(wedding_id: @wedding.id, key: Wedding::PHOTO_STYLE_METADATA_KEY).value
      assert_equal "false", WeddingMetadata.find_by(wedding_id: @wedding.id, key: "rsvp_visible").value
    end
  end
end

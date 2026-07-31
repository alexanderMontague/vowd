require "test_helper"

module Admin
  class SettingsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      @admin = create_admin_for(@wedding)
      sign_in_admin(@admin)
    end

    teardown do
      WeddingMetadata.where(wedding_id: @wedding.id).delete_all
    end

    test "shows settings with the current photo style selected" do
      get admin_settings_path

      assert_response :success
      assert_includes response.body, "Photo Display Style"
      assert_includes response.body, "form-autosave"
      assert_includes response.body, "Changes save automatically"
    end

    test "shows settings when wedding date is blank" do
      @wedding.update!(date: nil, ceremony_time: nil)

      get admin_settings_path

      assert_redirected_to admin_website_path
    end

    test "json update autosaves settings without redirect" do
      patch admin_settings_path,
            params: { dispo_photo_style: "bw", flags: { "dispo_gallery_on_main_page" => "true" } },
            as: :json

      assert_response :success
      assert_equal true, response.parsed_body["ok"]
      assert_equal "bw", @wedding.reload.dispo_photo_style
    end

    test "ignores an unknown photo style" do
      patch admin_settings_path, params: { dispo_photo_style: "polaroid" }

      assert_redirected_to admin_settings_path
      assert_nil WeddingMetadata.find_by(wedding_id: @wedding.id, key: Wedding::PHOTO_STYLE_METADATA_KEY)
    end

    test "updates photo style alongside feature flags" do
      patch admin_settings_path, params: {
        dispo_photo_style: "original",
        flags: { "dispo_gallery_on_main_page" => "false" }
      }

      assert_redirected_to admin_settings_path
      assert_equal "original", WeddingMetadata.find_by(wedding_id: @wedding.id, key: Wedding::PHOTO_STYLE_METADATA_KEY).value
      assert_equal "false", WeddingMetadata.find_by(wedding_id: @wedding.id, key: "dispo_gallery_on_main_page").value
    end
  end
end

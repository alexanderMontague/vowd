require "test_helper"

module Admin
  module Website
    class AssetsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @wedding = create_wedding
        @admin = create_admin_for(@wedding)
        sign_in_admin(@admin)
        DisposableCamera::StorageClient.reset_adapter!
      end

      teardown do
        DisposableCamera::StorageClient.reset_adapter!
      end

      test "uploads a site asset under the wedding prefix" do
        file = fixture_file_upload("test_image.jpg", "image/jpeg")

        post admin_website_assets_path, params: { purpose: "hero", file: file }

        assert_response :created
        body = JSON.parse(response.body)
        assert body["object_key"].start_with?("#{Rails.env}/#{@wedding.id}/site/hero/")
        assert body["object_key"].end_with?(".webp")
        assert_includes body["url"], "/site-assets/"
        assert_includes body["thumbnail_url"], ".thumb.webp"
        assert File.exist?(Rails.public_path.join("uploads/disposable_camera", body["object_key"]))
        thumb_key = WeddingAssets::ObjectKeyBuilder.thumbnail_key(body["object_key"])
        assert File.exist?(Rails.public_path.join("uploads/disposable_camera", thumb_key))
      end

      test "rejects unsupported purpose" do
        file = fixture_file_upload("test_image.jpg", "image/jpeg")

        post admin_website_assets_path, params: { purpose: "other", file: file }

        assert_response :unprocessable_content
      end
    end
  end
end

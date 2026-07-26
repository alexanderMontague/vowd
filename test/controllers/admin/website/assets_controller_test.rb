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
        post admin_website_assets_path, params: { purpose: "hero", file: image_upload }, headers: json_headers

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

      test "every upload joins the photo library" do
        assert_difference -> { @wedding.wedding_assets.count }, 1 do
          post admin_website_assets_path, params: { purpose: "photos", file: image_upload }, headers: json_headers
        end

        assert_response :created
        asset = @wedding.wedding_assets.last
        assert_equal response.parsed_body["id"], asset.id
        assert_equal "image/webp", asset.content_type
        assert asset.byte_size.positive?
      end

      test "renders a turbo stream so the library and picker options stay in sync" do
        post admin_website_assets_path,
             params: { purpose: "photos", file: image_upload },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        assert_response :created
        asset = @wedding.wedding_assets.last
        assert_includes response.body, %(target="photo_library")
        assert_includes response.body, %(target="photo_library_options")
        assert_includes response.body, asset.id
      end

      test "uploads an invitation video, captures a poster, and places it" do
        assert_difference -> { @wedding.wedding_assets.count }, 1 do
          post admin_website_assets_path,
               params: { purpose: "invitation", file: video_upload },
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        end

        assert_response :created
        asset = @wedding.wedding_assets.last
        assert_equal "video/mp4", asset.content_type
        assert asset.object_key.end_with?(".mp4")
        assert_equal [asset.id], @wedding.reload.placements["invitation_envelope"]
        assert_includes response.body, %(target="envelope_open_section")

        thumb_key = WeddingAssets::ObjectKeyBuilder.thumbnail_key(asset.object_key)
        assert File.exist?(Rails.public_path.join("uploads/disposable_camera", asset.object_key))
        assert File.exist?(Rails.public_path.join("uploads/disposable_camera", thumb_key))
        assert thumb_key.end_with?(".thumb.webp")
      end

      test "replacing the envelope video destroys the previous one" do
        post admin_website_assets_path,
             params: { purpose: "invitation", file: video_upload },
             headers: json_headers
        first = @wedding.wedding_assets.last

        assert_difference -> { @wedding.wedding_assets.count }, 0 do
          post admin_website_assets_path,
               params: { purpose: "invitation", file: video_upload },
               headers: json_headers
        end

        second = @wedding.wedding_assets.last
        assert_not_equal first.id, second.id
        assert_not WeddingAsset.exists?(first.id)
        assert_equal [second.id], @wedding.reload.placements["invitation_envelope"]
      end

      test "rejects image purpose for video uploads" do
        post admin_website_assets_path, params: { purpose: "photos", file: video_upload }, headers: json_headers

        assert_response :unprocessable_content
      end

      test "rejects unsupported purpose" do
        post admin_website_assets_path, params: { purpose: "other", file: image_upload }, headers: json_headers

        assert_response :unprocessable_content
      end

      test "updates alt text" do
        asset = create_asset!

        patch admin_website_asset_path(asset), params: { wedding_asset: { alt: "On the pier" } }, as: :json

        assert_response :success
        assert_equal "On the pier", asset.reload.alt
      end

      test "destroys an asset" do
        asset = create_asset!

        assert_difference -> { @wedding.wedding_assets.count }, -1 do
          delete admin_website_asset_path(asset), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        end

        assert_response :success
        assert_includes response.body, %(action="remove")
      end

      test "destroying the envelope video clears the placement" do
        post admin_website_assets_path,
             params: { purpose: "invitation", file: video_upload },
             headers: json_headers
        asset = @wedding.wedding_assets.last

        delete admin_website_asset_path(asset), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        assert_response :success
        assert_nil @wedding.reload.placements["invitation_envelope"]
        assert_includes response.body, %(target="envelope_open_section")
      end

      test "cannot touch another wedding's asset" do
        other = create_wedding
        asset = other.wedding_assets.create!(
          object_key: "#{Rails.env}/#{other.id}/site/photos/other.webp",
          content_type: "image/webp",
          byte_size: 1024
        )

        delete admin_website_asset_path(asset), as: :json

        assert_response :not_found
        assert asset.reload.persisted?
      end

      private

      def image_upload
        fixture_file_upload("test_image.jpg", "image/jpeg")
      end

      def video_upload
        fixture_file_upload("test_video.mp4", "video/mp4")
      end

      def json_headers
        { "Accept" => "application/json" }
      end

      def create_asset!
        @wedding.wedding_assets.create!(
          object_key: "#{Rails.env}/#{@wedding.id}/site/photos/#{SecureRandom.hex(4)}.webp",
          content_type: "image/webp",
          byte_size: 2048
        )
      end
    end
  end
end

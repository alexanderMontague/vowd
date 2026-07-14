require "test_helper"

module Public
  class SiteAssetsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      host_wedding!(@wedding)
      DisposableCamera::StorageClient.reset_adapter!
      @object_key = WeddingAssets::ObjectKeyBuilder.build(
        wedding_id: @wedding.id,
        purpose: "gallery",
        content_type: "image/jpeg"
      )
      path = Rails.public_path.join("uploads/disposable_camera", @object_key)
      FileUtils.mkdir_p(path.dirname)
      File.binwrite(path, "fake-image-bytes")
    end

    teardown do
      path = Rails.public_path.join("uploads/disposable_camera", @object_key)
      FileUtils.rm_f(path)
      DisposableCamera::StorageClient.reset_adapter!
    end

    test "streams an asset belonging to the current wedding" do
      get public_site_asset_path(object_key: @object_key)

      assert_response :success
      assert_equal "image/jpeg", response.media_type
      assert_equal "fake-image-bytes", response.body
    end

    test "returns not found for another wedding key" do
      foreign_key = @object_key.sub("/#{@wedding.id}/", "/other-wedding/")

      get public_site_asset_path(object_key: foreign_key)

      assert_response :not_found
    end
  end
end

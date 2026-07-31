require "test_helper"

module Dispo
  class CamerasControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding(id: "loadtest")
      host_wedding!(@wedding)
      WeddingMetadata.create!(
        wedding_id: @wedding.id,
        key: "dispo_accepting_photos",
        value: "true"
      )
      @image = fixture_file_upload("test_image.jpg", "image/jpeg")
    end

    teardown do
      WeddingMetadata.where(wedding_id: @wedding.id).delete_all
      DisposablePhoto.where(wedding_id: @wedding.id).delete_all
    end

    test "upload stores a normal object key without loadtest header" do
      DisposableCamera::StorageClient.stub(:upload!, true) do
        post dispo_upload_path, params: { photo: @image, flash_enabled: false }
      end

      assert_response :created
      photo = DisposablePhoto.find(response.parsed_body["id"])
      assert_match(%r{\Atest/loadtest/photos/\d{8}-\d{6}-[0-9a-f]{16}\.jpg\z}, photo.object_key)
    end

    test "upload tags object key when loadtest header matches LOADTEST_WEDDING_ID" do
      with_env("LOADTEST_WEDDING_ID" => "loadtest") do
        DisposableCamera::StorageClient.stub(:upload!, true) do
          post dispo_upload_path,
               params: { photo: @image, flash_enabled: false },
               headers: { "X-Vowd-Loadtest-Run" => "20260730T213000Z-99" }
        end
      end

      assert_response :created
      photo = DisposablePhoto.find(response.parsed_body["id"])
      assert_match(
        %r{\Atest/loadtest/photos/lt/20260730T213000Z-99/\d{8}-\d{6}-[0-9a-f]{16}\.jpg\z},
        photo.object_key
      )
    end

    test "upload ignores loadtest header on non-loadtest wedding" do
      other = create_wedding(id: "real-wedding")
      host_wedding!(other)
      WeddingMetadata.create!(
        wedding_id: other.id,
        key: "dispo_accepting_photos",
        value: "true"
      )

      with_env("LOADTEST_WEDDING_ID" => "loadtest") do
        DisposableCamera::StorageClient.stub(:upload!, true) do
          post dispo_upload_path,
               params: { photo: @image, flash_enabled: false },
               headers: { "X-Vowd-Loadtest-Run" => "should-ignore" }
        end
      end

      assert_response :created
      photo = DisposablePhoto.find(response.parsed_body["id"])
      assert_match(%r{\Atest/real-wedding/photos/\d{8}-\d{6}-[0-9a-f]{16}\.jpg\z}, photo.object_key)
      refute_includes photo.object_key, "/lt/"
    ensure
      WeddingMetadata.where(wedding_id: other.id).delete_all
      DisposablePhoto.where(wedding_id: other.id).delete_all
    end
  end
end

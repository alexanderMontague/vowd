require "test_helper"

module Dispo
  class GalleriesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = Wedding.current
      WeddingMetadata.create!(
        wedding_id: @wedding.id,
        key: "dispo_gallery_on_main_page",
        value: "true"
      )
      @photo = DisposablePhoto.create!(
        wedding_id: @wedding.id,
        object_key: "test/#{SecureRandom.hex(8)}.jpg",
        content_type: "image/jpeg",
        byte_size: 2048,
        flash_enabled: false,
        captured_at: Time.current,
        source_ip: "127.0.0.1"
      )
    end

    teardown do
      WeddingMetadata.where(wedding_id: @wedding.id).delete_all
      DisposablePhoto.where(wedding_id: @wedding.id).delete_all
    end

    test "raw streams the original bytes same-origin for canvas export" do
      DisposableCamera::StorageClient.stub(:download_object, StringIO.new("photo-bytes")) do
        get dispo_photo_raw_path(@photo)
      end

      assert_response :success
      assert_equal "image/jpeg", response.media_type
      assert_equal "photo-bytes", response.body
    end

    test "raw is scoped to the current wedding" do
      other = DisposablePhoto.create!(
        wedding_id: "other-wedding",
        object_key: "test/#{SecureRandom.hex(8)}.jpg",
        content_type: "image/jpeg",
        byte_size: 2048,
        flash_enabled: false,
        captured_at: Time.current,
        source_ip: "127.0.0.1"
      )

      get dispo_photo_raw_path(other)

      assert_response :not_found
    end

    test "raw 404s when the gallery is hidden" do
      WeddingMetadata.where(wedding_id: @wedding.id, key: "dispo_gallery_on_main_page").delete_all

      get dispo_photo_raw_path(@photo)

      assert_response :not_found
    end
  end
end

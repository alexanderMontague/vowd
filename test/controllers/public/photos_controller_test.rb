require "test_helper"

module Public
  class PhotosControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = Wedding.current
      WeddingMetadata.create!(
        wedding_id: @wedding.id,
        key: "dispo_gallery_on_main_page",
        value: "true"
      )
    end

    teardown do
      WeddingMetadata.where(wedding_id: @wedding.id).delete_all
      DisposablePhoto.where(wedding_id: @wedding.id).delete_all
    end

    test "caps the dispo preview and links to the full gallery" do
      15.times { |index| create_photo!(index) }

      get public_gallery_path

      assert_response :success
      assert_select ".retro-photo", Public::PhotosController::DISPO_PREVIEW_LIMIT
      assert_select %(a[href="#{dispo_gallery_path}"]), text: /View the Full Gallery/
    end

    private

    def create_photo!(index)
      DisposablePhoto.create!(
        wedding_id: @wedding.id,
        object_key: "test/#{SecureRandom.hex(8)}.jpg",
        content_type: "image/jpeg",
        byte_size: 2048,
        flash_enabled: false,
        captured_at: Time.current - index.minutes,
        source_ip: "127.0.0.1"
      )
    end
  end
end

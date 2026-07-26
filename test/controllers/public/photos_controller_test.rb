require "test_helper"

module Public
  class PhotosControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      host_wedding!(@wedding)
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

    test "renders curated gallery sections" do
      @wedding.update!(
        photos_page: {
          "title" => "Our Photos",
          "subtitle" => "Moments",
          "homepage_enabled" => true,
          "homepage_title" => "Gallery",
          "homepage_limit" => 6,
          "sections" => [
            {
              "title" => "Engagement",
              "images" => [{ "object_key" => "test/#{@wedding.id}/site/photos/a.jpg", "alt" => "Park" }]
            }
          ]
        }
      )

      get public_gallery_path

      assert_response :success
      assert_includes response.body, "Engagement"
      assert_includes response.body, "Our Photos"
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

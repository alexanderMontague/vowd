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

      get public_photos_path

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

      get public_photos_path

      assert_response :success
      assert_includes response.body, "Engagement"
      assert_includes response.body, "Our Photos"
    end

    test "renders section photos referenced from the library" do
      asset = @wedding.wedding_assets.create!(
        object_key: "#{Rails.env}/#{@wedding.id}/site/photos/library.webp",
        content_type: "image/webp",
        byte_size: 1024,
        alt: "On the pier"
      )
      @wedding.update!(
        photos_page: {
          "title" => "Our Photos",
          "sections" => [{ "title" => "Engagement", "asset_ids" => [asset.id] }]
        }
      )

      get public_photos_path

      assert_response :success
      assert_select %(img[alt="On the pier"])
      assert_includes response.body, public_site_asset_path(object_key: asset.object_key)
    end

    test "legacy gallery path redirects to photos" do
      get "/gallery"

      assert_redirected_to "/photos"
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

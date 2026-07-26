require "test_helper"

class WeddingTest < ActiveSupport::TestCase
  setup do
    @wedding = create_wedding
  end

  teardown do
    WeddingMetadata.where(wedding_id: @wedding.id, key: Wedding::PHOTO_STYLE_METADATA_KEY).delete_all
  end

  test "dispo_photo_style defaults when no override exists" do
    assert_equal Wedding::DEFAULT_PHOTO_STYLE, @wedding.dispo_photo_style
  end

  test "dispo_photo_style returns a valid stored override" do
    set_style_override("bw")

    assert_equal "bw", @wedding.dispo_photo_style
  end

  test "dispo_photo_style falls back to default for an invalid override" do
    set_style_override("polaroid")

    assert_equal Wedding::DEFAULT_PHOTO_STYLE, @wedding.dispo_photo_style
  end

  test "configured? requires partners and a date" do
    unconfigured = create_wedding(partner1: nil, partner2: nil, date: nil)

    assert_not unconfigured.configured?

    unconfigured.update!(partner1: "Britt", partner2: "Alex", date: Date.new(2027, 8, 1))
    assert unconfigured.configured?
  end

  test "dispo_camera_closes_at is safe when date is blank" do
    wedding = create_wedding(date: nil, ceremony_time: nil)

    assert_kind_of ActiveSupport::TimeWithZone, wedding.dispo_camera_closes_at
    assert_nothing_raised { wedding.dispo_camera_locked? }
  end

  test "new weddings receive a starter FAQ question" do
    wedding = Wedding.create!(
      id: "faq-default-#{SecureRandom.hex(3)}",
      title: "FAQ Defaults"
    )

    assert_equal 1, wedding.faq["questions"].size
    assert wedding.faq["questions"].first["question"].present?
  ensure
    wedding&.destroy
  end

  test "gallery_content falls back to legacy gallery images" do
    @wedding.update!(
      photos_page: Wedding::DEFAULT_PHOTOS_PAGE.deep_dup,
      gallery: {
        "enabled" => true,
        "title" => "Moments",
        "images" => [{ "object_key" => "test/photo.jpg", "alt" => "Us" }]
      }
    )

    content = @wedding.gallery_content
    assert_equal "Moments", content["sections"].first["title"]
    assert_equal true, content["homepage_enabled"]
    assert_equal 1, @wedding.homepage_gallery_images.size
    assert @wedding.homepage_gallery_visible?
  end

  test "homepage_gallery_images respects limit across sections" do
    @wedding.update!(
      photos_page: {
        "title" => "Photos",
        "subtitle" => "",
        "homepage_enabled" => true,
        "homepage_title" => "Gallery",
        "homepage_limit" => 2,
        "sections" => [
          {
            "title" => "Engagement",
            "images" => [
              { "object_key" => "a.jpg", "alt" => "A" },
              { "object_key" => "b.jpg", "alt" => "B" }
            ]
          },
          {
            "title" => "Memories",
            "images" => [{ "object_key" => "c.jpg", "alt" => "C" }]
          }
        ]
      }
    )

    assert_equal %w[a.jpg b.jpg], @wedding.homepage_gallery_images.map { |image| image["object_key"] }
  end

  private

  def set_style_override(value)
    WeddingMetadata.create!(
      wedding_id: @wedding.id,
      key: Wedding::PHOTO_STYLE_METADATA_KEY,
      value: value
    )
  end
end

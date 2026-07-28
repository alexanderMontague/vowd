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

  test "venue_label prefers address over name for the location line" do
    @wedding.update!(
      venue_name: "Liberty Grand",
      venue_address: "25 British Columbia Rd",
      venue_city: "Toronto",
      venue_region: "Ontario"
    )

    assert_equal "25 British Columbia Rd, Toronto, Ontario", @wedding.venue_label
  end

  test "venue_label falls back to name when address is blank" do
    @wedding.update!(
      venue_name: "Liberty Grand",
      venue_address: nil,
      venue_city: "Toronto",
      venue_region: "Ontario"
    )

    assert_equal "Liberty Grand, Toronto, Ontario", @wedding.venue_label
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

  test "gallery_sections resolves library assets ahead of legacy url entries" do
    first = create_asset(position: 0)
    second = create_asset(position: 1)
    @wedding.update!(
      photos_page: {
        "sections" => [
          {
            "title" => "Engagement",
            "asset_ids" => [second.id, first.id],
            "images" => [{ "url" => "https://example.com/remote.jpg" }]
          }
        ]
      }
    )

    images = @wedding.gallery_sections.first["images"]
    assert_equal [second, first], images.first(2)
    assert_equal "https://example.com/remote.jpg", images.last["url"]
  end

  test "gallery_sections drops asset ids that no longer resolve" do
    asset = create_asset
    @wedding.update!(
      photos_page: { "sections" => [{ "title" => "Engagement", "asset_ids" => [asset.id, SecureRandom.uuid] }] }
    )

    assert_equal [asset], @wedding.gallery_sections.first["images"]
  end

  test "placements_for returns assets in the configured order" do
    first = create_asset(position: 0)
    second = create_asset(position: 1)
    @wedding.update!(placements: { "save_the_date_floating" => [second.id, first.id] })

    assert_equal [second, first], @wedding.placements_for("save_the_date_floating")
  end

  test "placements_for prunes missing ids and clamps to the slot maximum" do
    assets = Array.new(6) { |index| create_asset(position: index) }
    @wedding.update!(
      placements: {
        "save_the_date_floating" => [assets[0].id, SecureRandom.uuid, *assets[1..5].map(&:id)]
      }
    )

    assert_equal assets.first(5), @wedding.placements_for("save_the_date_floating")
  end

  test "event_starts_at uses ceremony_time when present" do
    @wedding.update!(date: Date.new(2027, 5, 10), ceremony_time: "5:30 PM", timezone: "America/Los_Angeles")

    start = @wedding.event_starts_at
    assert_equal 17, start.hour
    assert_equal 30, start.min
    assert_equal "America/Los_Angeles", start.time_zone.name
  end

  test "event_starts_at defaults to mid-afternoon when ceremony_time is blank" do
    @wedding.update!(date: Date.new(2027, 5, 10), ceremony_time: nil, timezone: "America/Los_Angeles")

    start = @wedding.event_starts_at
    assert_equal 16, start.hour
    assert_equal 0, start.min
  end

  test "event_ends_at is duration hours after the start" do
    @wedding.update!(
      date: Date.new(2027, 5, 10),
      ceremony_time: "4:00 PM",
      wedding_duration_hours: 5,
      timezone: "America/Los_Angeles"
    )

    assert_equal @wedding.event_starts_at + 5.hours, @wedding.event_ends_at
  end

  test "placement returns the first asset and nil for empty or unknown slots" do
    asset = create_asset
    @wedding.update!(placements: { "rsvp_portrait" => [asset.id] })

    assert_equal asset, @wedding.placement("rsvp_portrait")
    assert_nil @wedding.placement("save_the_date_vase")
    assert_empty @wedding.placements_for("not_a_slot")
  end

  private

  def create_asset(attrs = {})
    @wedding.wedding_assets.create!(
      {
        object_key: "#{Rails.env}/#{@wedding.id}/site/photos/#{SecureRandom.hex(6)}.webp",
        content_type: "image/webp",
        byte_size: 2048
      }.merge(attrs)
    )
  end

  def set_style_override(value)
    WeddingMetadata.create!(
      wedding_id: @wedding.id,
      key: Wedding::PHOTO_STYLE_METADATA_KEY,
      value: value
    )
  end
end

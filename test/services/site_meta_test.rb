require "test_helper"

class SiteMetaTest < ActiveSupport::TestCase
  setup do
    @wedding = create_wedding(
      title: "Britt & Alex",
      date: Date.new(2027, 7, 10),
      venue_name: "The Grand Hall",
      venue_city: "Toronto",
      venue_region: "Ontario"
    )
  end

  test "the title names the couple and the day" do
    assert_equal "Britt & Alex · Saturday, July 10, 2027", meta.title
  end

  test "the title drops the date when the day is not set" do
    @wedding.update!(date: nil)

    assert_equal "Britt & Alex", meta.title
  end

  test "the description invites guests with the date and venue" do
    assert_equal "Join us on Saturday, July 10, 2027 at The Grand Hall, Toronto, Ontario.", meta.description
  end

  test "the description uses the street address when set" do
    @wedding.update!(venue_address: "25 British Columbia Rd")

    assert_equal "Join us on Saturday, July 10, 2027 at 25 British Columbia Rd, Toronto, Ontario.", meta.description
  end

  test "the description keeps whichever of date and venue exists" do
    @wedding.update!(venue_name: nil, venue_address: nil, venue_city: nil, venue_region: nil)
    assert_equal "Join us on Saturday, July 10, 2027.", meta.description

    @wedding.update!(date: nil, venue_name: "The Grand Hall")
    assert_equal "Join us at The Grand Hall.", meta.description
  end

  test "the description falls back to the hero tagline, then to a generic line" do
    @wedding.update!(date: nil, venue_name: nil, venue_address: nil, venue_city: nil, venue_region: nil,
                     hero: { "tagline" => "Request the Honour of Your Presence" })

    assert_equal "Request the Honour of Your Presence", meta.description

    @wedding.update!(hero: {})

    assert_equal SiteMeta::FALLBACK_DESCRIPTION, meta.description
  end

  test "the hero photo is the first image candidate" do
    hero_asset = create_asset
    place("homepage_hero", hero_asset)
    place("save_the_date_portrait", create_asset)

    assert_equal hero_asset, meta.image_candidates.first
  end

  test "an explicit share image overrides the hero for link previews" do
    hero_asset = create_asset
    share_asset = create_asset
    place("homepage_hero", hero_asset)
    place("share_image", share_asset)

    assert_equal share_asset, meta.image_candidates.first
  end

  test "share image falls back to the hero when unset" do
    hero_asset = create_asset
    place("homepage_hero", hero_asset)

    assert_equal hero_asset, @wedding.share_image
    assert_equal hero_asset, meta.image_candidates.first
  end

  test "a legacy inline hero photo is still a candidate" do
    hero = { "tagline" => "Hello", "object_key" => "hero.webp" }
    @wedding.update!(hero: hero)

    assert_equal hero, meta.image_candidates.first
  end

  test "a placed photo stands in for a hero the couple never set" do
    portrait = create_asset
    place("save_the_date_portrait", portrait)

    assert_equal portrait, meta.image_candidates.first
  end

  test "a gallery photo is the last resort" do
    gallery_photo = create_asset
    @wedding.update!(photos_page: { "sections" => [{ "title" => "Engagement", "asset_ids" => [gallery_photo.id] }] })

    assert_equal gallery_photo, meta.image_candidates.first
  end

  test "a hero that only holds a tagline is not a photo candidate" do
    @wedding.update!(hero: { "tagline" => "Hello", "object_key" => nil, "image_url" => "" })

    assert_empty meta.image_candidates
  end

  test "a missing wedding falls back to neutral copy" do
    blank = SiteMeta.new(nil)

    assert_equal SiteMeta::FALLBACK_TITLE, blank.title
    assert_equal SiteMeta::FALLBACK_DESCRIPTION, blank.description
    assert_empty blank.image_candidates
  end

  private

  def meta
    SiteMeta.new(@wedding.reload)
  end

  def create_asset
    @wedding.wedding_assets.create!(
      object_key: "#{Rails.env}/#{@wedding.id}/site/photos/#{SecureRandom.hex(6)}.webp",
      content_type: "image/webp",
      byte_size: 2048
    )
  end

  def place(slot_key, asset)
    @wedding.update!(placements: @wedding.placements.merge(slot_key => [asset.id]))
  end
end

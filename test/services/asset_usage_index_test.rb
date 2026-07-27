require "test_helper"

class AssetUsageIndexTest < ActiveSupport::TestCase
  setup do
    @wedding = create_wedding
  end

  test "indexes placements across pages" do
    hero = create_asset
    floating = create_asset
    @wedding.update!(
      placements: {
        "homepage_hero" => [hero.id],
        "rsvp_floating" => [floating.id],
        "save_the_date_portrait" => [hero.id]
      }
    )

    labels = AssetUsageIndex.call(@wedding)

    assert_equal ["Homepage · Hero image", "Save the Date · Framed portrait"].sort,
                 labels[hero.id].sort
    assert_equal ["RSVP · Floating photos"], labels[floating.id]
  end

  test "indexes gallery sections and party members" do
    gallery = create_asset
    bridesmaid = create_asset
    @wedding.update!(
      photos_page: {
        "sections" => [{ "title" => "Engagement", "asset_ids" => [gallery.id] }]
      },
      wedding_party: {
        "bridesmaids" => [{ "name" => "Ada", "asset_id" => bridesmaid.id }],
        "groomsmen" => []
      }
    )

    labels = AssetUsageIndex.call(@wedding)

    assert_equal ["Photos page · Engagement"], labels[gallery.id]
    assert_equal ["Bridesmaid · Ada"], labels[bridesmaid.id]
  end

  test "ignores blank asset ids and skips video slots" do
    photo = create_asset
    @wedding.update!(
      placements: {
        "rsvp_portrait" => [photo.id, ""],
        "invitation_envelope" => [SecureRandom.uuid]
      }
    )

    labels = AssetUsageIndex.call(@wedding)

    assert_equal ["RSVP · Framed portrait"], labels[photo.id]
    assert labels.values.none? { |placed| placed.any? { |label| label.include?("Envelope") } }
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
end

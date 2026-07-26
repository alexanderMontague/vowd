require "test_helper"

class WeddingAssetTest < ActiveSupport::TestCase
  setup do
    @wedding = create_wedding
  end

  test "assigns a uuid primary key" do
    asset = build_asset

    assert asset.save
    assert_match(/\A[0-9a-f-]{36}\z/, asset.id)
  end

  test "requires a supported content type" do
    asset = build_asset(content_type: "image/gif")

    assert_not asset.valid?
    assert_includes asset.errors[:content_type], "is not included in the list"
  end

  test "accepts video content types" do
    asset = build_asset(
      object_key: "#{Rails.env}/#{@wedding.id}/site/invitation/clip.mp4",
      content_type: "video/mp4"
    )

    assert asset.valid?
    assert asset.video?
  end

  test "derives a webp poster key for videos" do
    asset = build_asset(
      object_key: "#{Rails.env}/#{@wedding.id}/site/invitation/clip.mp4",
      content_type: "video/mp4"
    )

    assert_equal "#{Rails.env}/#{@wedding.id}/site/invitation/clip.thumb.webp", asset.thumbnail_object_key
  end

  test "object keys are unique across weddings" do
    key = "#{Rails.env}/#{@wedding.id}/site/photos/one.webp"
    build_asset(object_key: key).save!

    duplicate = create_wedding.wedding_assets.build(
      object_key: key,
      content_type: "image/webp",
      byte_size: 1024
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:object_key], "has already been taken"
  end

  test "allows a missing byte size for imported assets but rejects a zero" do
    assert build_asset(byte_size: nil).valid?
    assert_not build_asset(byte_size: 0).valid?
  end

  test "ordered sorts by position then creation" do
    third = build_asset(object_key: unique_key, position: 2).tap(&:save!)
    first = build_asset(object_key: unique_key, position: 0).tap(&:save!)
    second = build_asset(object_key: unique_key, position: 1).tap(&:save!)

    assert_equal [first, second, third], @wedding.wedding_assets.ordered.to_a
  end

  test "derives the thumbnail object key" do
    asset = build_asset(object_key: "#{Rails.env}/#{@wedding.id}/site/photos/one.webp")

    assert_equal "#{Rails.env}/#{@wedding.id}/site/photos/one.thumb.webp", asset.thumbnail_object_key
  end

  private

  def build_asset(attrs = {})
    @wedding.wedding_assets.build(
      { object_key: unique_key, content_type: "image/webp", byte_size: 2048 }.merge(attrs)
    )
  end

  def unique_key
    "#{Rails.env}/#{@wedding.id}/site/photos/#{SecureRandom.hex(6)}.webp"
  end
end

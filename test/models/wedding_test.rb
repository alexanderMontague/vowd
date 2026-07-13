require "test_helper"

class WeddingTest < ActiveSupport::TestCase
  setup do
    @wedding = Wedding.current
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

  private

  def set_style_override(value)
    WeddingMetadata.create!(
      wedding_id: @wedding.id,
      key: Wedding::PHOTO_STYLE_METADATA_KEY,
      value: value
    )
  end
end

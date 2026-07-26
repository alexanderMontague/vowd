require "test_helper"

module WeddingAssets
  class ObjectKeyBuilderTest < ActiveSupport::TestCase
    test "builds invitation video keys under the wedding site prefix" do
      key = ObjectKeyBuilder.build(
        wedding_id: "demo",
        purpose: "invitation",
        content_type: "video/mp4"
      )

      assert_match %r{\A#{Rails.env}/demo/site/invitation/.+\.mp4\z}, key
    end

    test "thumbnail key for videos uses a webp poster suffix" do
      key = "#{Rails.env}/demo/site/invitation/clip.mp4"

      assert_equal "#{Rails.env}/demo/site/invitation/clip.thumb.webp", ObjectKeyBuilder.thumbnail_key(key)
    end

    test "thumbnail key for images keeps the image extension" do
      key = "#{Rails.env}/demo/site/photos/one.webp"

      assert_equal "#{Rails.env}/demo/site/photos/one.thumb.webp", ObjectKeyBuilder.thumbnail_key(key)
    end

    test "content_type_for recognizes mp4" do
      assert_equal "video/mp4", ObjectKeyBuilder.content_type_for("clip.mp4")
    end
  end
end

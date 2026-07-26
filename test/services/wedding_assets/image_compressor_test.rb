require "test_helper"

module WeddingAssets
  class ImageCompressorTest < ActiveSupport::TestCase
    test "converts uploads to webp under the max edge and builds a thumbnail" do
      uploaded = Rack::Test::UploadedFile.new(
        Rails.root.join("test/fixtures/files/test_image.jpg"),
        "image/jpeg"
      )

      result = ImageCompressor.call(uploaded_file: uploaded)

      assert_equal "image/webp", result.content_type
      assert result.byte_size.positive?
      assert result.byte_size < uploaded.size

      image = Vips::Image.new_from_buffer(result.io.read, "")
      assert image.width <= ImageCompressor::MAX_EDGE
      assert image.height <= ImageCompressor::MAX_EDGE

      thumb = Vips::Image.new_from_buffer(result.thumbnail_io.read, "")
      assert_equal ImageCompressor::THUMB_EDGE, thumb.width
      assert_equal ImageCompressor::THUMB_EDGE, thumb.height
    ensure
      result&.close
    end
  end
end

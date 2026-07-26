require "test_helper"

module WeddingAssets
  class VideoProcessorTest < ActiveSupport::TestCase
    test "transcodes to mp4 and builds a webp poster from the first frame" do
      uploaded = Rack::Test::UploadedFile.new(
        Rails.root.join("test/fixtures/files/test_video.mp4"),
        "video/mp4"
      )

      result = VideoProcessor.call(uploaded_file: uploaded)

      assert_equal "video/mp4", result.content_type
      assert_equal "image/webp", result.thumbnail_content_type
      assert result.byte_size.positive?
      assert result.io.read(8).bytesize.positive?

      poster = Vips::Image.new_from_buffer(result.thumbnail_io.read, "")
      assert poster.width.positive?
      assert poster.height.positive?
    ensure
      result&.close
    end
  end
end

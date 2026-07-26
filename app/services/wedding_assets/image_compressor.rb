require "image_processing/vips"

module WeddingAssets
  # Compresses curated site uploads to WebP and builds a small admin thumbnail.
  class ImageCompressor
    MAX_EDGE = 2400
    THUMB_EDGE = 320
    QUALITY = 82
    THUMB_QUALITY = 70
    OUTPUT_CONTENT_TYPE = "image/webp".freeze

    Result = Struct.new(:io, :thumbnail_io, :content_type, :byte_size, keyword_init: true) do
      def close
        io.close if io.respond_to?(:close) && !io.closed?
        thumbnail_io.close if thumbnail_io.respond_to?(:close) && !thumbnail_io.closed?
      end
    end

    def self.call(uploaded_file:)
      new(uploaded_file).call
    end

    def initialize(uploaded_file)
      @uploaded_file = uploaded_file
    end

    def call
      source = ImageProcessing::Vips.source(source_path)

      full = source
        .resize_to_limit(MAX_EDGE, MAX_EDGE)
        .convert("webp")
        .saver(quality: QUALITY, strip: true)
        .call

      thumbnail = ImageProcessing::Vips
        .source(full.path)
        .resize_to_fill(THUMB_EDGE, THUMB_EDGE)
        .convert("webp")
        .saver(quality: THUMB_QUALITY, strip: true)
        .call

      Result.new(
        io: File.open(full.path, "rb"),
        thumbnail_io: File.open(thumbnail.path, "rb"),
        content_type: OUTPUT_CONTENT_TYPE,
        byte_size: File.size(full.path)
      )
    end

    private

    def source_path
      tempfile = @uploaded_file.tempfile
      tempfile.rewind if tempfile.respond_to?(:rewind)
      tempfile.path
    end
  end
end

module WeddingAssets
  class Uploader
    MAX_IMAGE_BYTES = 15.megabytes
    MAX_VIDEO_BYTES = 50.megabytes
    IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
    VIDEO_CONTENT_TYPES = %w[video/mp4 video/webm video/quicktime].freeze
    CONTENT_TYPES = (IMAGE_CONTENT_TYPES + VIDEO_CONTENT_TYPES).freeze
    STORED_CONTENT_TYPES = (
      IMAGE_CONTENT_TYPES + [ImageCompressor::OUTPUT_CONTENT_TYPE, VideoProcessor::OUTPUT_CONTENT_TYPE]
    ).uniq.freeze

    def self.call(wedding:, purpose:, uploaded_file:)
      new(wedding: wedding, purpose: purpose, uploaded_file: uploaded_file).call
    end

    def initialize(wedding:, purpose:, uploaded_file:)
      @wedding = wedding
      @purpose = purpose
      @uploaded_file = uploaded_file
    end

    def call
      validate!
      video? ? upload_video : upload_image
    end

    private

    def upload_image
      compressed = nil
      compressed = ImageCompressor.call(uploaded_file: @uploaded_file)

      object_key = ObjectKeyBuilder.build(
        wedding_id: @wedding.id,
        purpose: @purpose,
        content_type: compressed.content_type
      )
      thumbnail_key = ObjectKeyBuilder.thumbnail_key(object_key)

      DisposableCamera::StorageClient.upload!(
        io: compressed.io,
        object_key: object_key,
        content_type: compressed.content_type
      )
      DisposableCamera::StorageClient.upload!(
        io: compressed.thumbnail_io,
        object_key: thumbnail_key,
        content_type: compressed.content_type
      )

      {
        object_key: object_key,
        thumbnail_object_key: thumbnail_key,
        content_type: compressed.content_type,
        byte_size: compressed.byte_size
      }
    ensure
      compressed&.close
    end

    def upload_video
      processed = nil
      processed = VideoProcessor.call(uploaded_file: @uploaded_file)

      object_key = ObjectKeyBuilder.build(
        wedding_id: @wedding.id,
        purpose: @purpose,
        content_type: processed.content_type
      )
      thumbnail_key = ObjectKeyBuilder.thumbnail_key(object_key)

      DisposableCamera::StorageClient.upload!(
        io: processed.io,
        object_key: object_key,
        content_type: processed.content_type
      )
      DisposableCamera::StorageClient.upload!(
        io: processed.thumbnail_io,
        object_key: thumbnail_key,
        content_type: processed.thumbnail_content_type
      )

      {
        object_key: object_key,
        thumbnail_object_key: thumbnail_key,
        content_type: processed.content_type,
        byte_size: processed.byte_size
      }
    ensure
      processed&.close
    end

    def validate!
      raise ArgumentError, "File is required." if @uploaded_file.blank?
      raise ArgumentError, "Unsupported purpose." unless ObjectKeyBuilder::PURPOSES.include?(@purpose.to_s)

      if video?
        raise ArgumentError, "Video is too large." if @uploaded_file.size > MAX_VIDEO_BYTES
        raise ArgumentError, "Unsupported video type." unless VIDEO_CONTENT_TYPES.include?(content_type)
        raise ArgumentError, "Unsupported purpose for video." unless @purpose.to_s == "invitation"
      else
        raise ArgumentError, "Image is too large." if @uploaded_file.size > MAX_IMAGE_BYTES
        raise ArgumentError, "Unsupported image type." unless IMAGE_CONTENT_TYPES.include?(content_type)
      end
    end

    def video?
      VIDEO_CONTENT_TYPES.include?(content_type)
    end

    def content_type
      @content_type ||= @uploaded_file.content_type.to_s
    end
  end
end

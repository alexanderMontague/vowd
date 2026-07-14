module WeddingAssets
  class Uploader
    MAX_UPLOAD_BYTES = 15.megabytes
    CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

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
      object_key = ObjectKeyBuilder.build(
        wedding_id: @wedding.id,
        purpose: @purpose,
        content_type: content_type
      )

      DisposableCamera::StorageClient.upload!(
        io: @uploaded_file.tempfile,
        object_key: object_key,
        content_type: content_type
      )

      { object_key: object_key, content_type: content_type, byte_size: @uploaded_file.size }
    end

    private

    def validate!
      raise ArgumentError, "Image is required." if @uploaded_file.blank?
      raise ArgumentError, "Image is too large." if @uploaded_file.size > MAX_UPLOAD_BYTES
      raise ArgumentError, "Unsupported image type." unless CONTENT_TYPES.include?(content_type)
      raise ArgumentError, "Unsupported purpose." unless ObjectKeyBuilder::PURPOSES.include?(@purpose.to_s)
    end

    def content_type
      @content_type ||= @uploaded_file.content_type.to_s
    end
  end
end

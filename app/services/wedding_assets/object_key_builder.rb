module WeddingAssets
  class ObjectKeyBuilder
    SITE_DIRECTORY = "site".freeze
    PURPOSES = %w[hero gallery party photos invitation].freeze
    VIDEO_EXTENSIONS = %w[.mp4 .webm .mov].freeze

    class << self
      def build(wedding_id:, purpose:, content_type:)
        purpose = purpose.to_s
        raise ArgumentError, "Unsupported purpose: #{purpose.inspect}" unless PURPOSES.include?(purpose)

        extension = extension_for(content_type)
        timestamp = Time.current.utc.strftime("%Y%m%d-%H%M%S")
        nonce = SecureRandom.hex(8)

        "#{Rails.env}/#{wedding_id}/#{SITE_DIRECTORY}/#{purpose}/#{timestamp}-#{nonce}.#{extension}"
      end

      def belongs_to_wedding?(object_key, wedding_id)
        prefix = "#{Rails.env}/#{wedding_id}/#{SITE_DIRECTORY}/"
        key = object_key.to_s
        key.start_with?(prefix) && !key.include?("..")
      end

      def thumbnail_key(object_key)
        key = object_key.to_s
        raise ArgumentError, "object_key is required" if key.blank?

        if video_key?(key)
          key.sub(/(\.[^.]+\z)/, ".thumb.webp")
        else
          key.sub(/(\.[^.]+\z)/, ".thumb\\1")
        end
      end

      def content_type_for(object_key)
        case File.extname(object_key.to_s).downcase
        when ".jpg", ".jpeg" then "image/jpeg"
        when ".png" then "image/png"
        when ".webp" then "image/webp"
        when ".mp4" then "video/mp4"
        when ".webm" then "video/webm"
        when ".mov" then "video/quicktime"
        else "application/octet-stream"
        end
      end

      def video_key?(object_key)
        VIDEO_EXTENSIONS.include?(File.extname(object_key.to_s).downcase)
      end

      private

      def extension_for(content_type)
        case content_type
        when "image/jpeg" then "jpg"
        when "image/png" then "png"
        when "image/webp" then "webp"
        when "video/mp4" then "mp4"
        when "video/webm" then "webm"
        when "video/quicktime" then "mov"
        else
          raise ArgumentError, "Unsupported content type: #{content_type.inspect}"
        end
      end
    end
  end
end

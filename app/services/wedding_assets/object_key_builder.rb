module WeddingAssets
  class ObjectKeyBuilder
    SITE_DIRECTORY = "site".freeze
    PURPOSES = %w[hero gallery party photos].freeze

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

      def content_type_for(object_key)
        case File.extname(object_key.to_s).downcase
        when ".jpg", ".jpeg" then "image/jpeg"
        when ".png" then "image/png"
        when ".webp" then "image/webp"
        else "application/octet-stream"
        end
      end

      private

      def extension_for(content_type)
        case content_type
        when "image/jpeg" then "jpg"
        when "image/png" then "png"
        when "image/webp" then "webp"
        else
          raise ArgumentError, "Unsupported content type: #{content_type.inspect}"
        end
      end
    end
  end
end

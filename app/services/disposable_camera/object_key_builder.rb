module DisposableCamera
  class ObjectKeyBuilder
    PHOTOS_DIRECTORY = "photos".freeze
    LOAD_TEST_DIRECTORY = "lt".freeze
    LOAD_TEST_RUN_ID_FORMAT = /\A[a-zA-Z0-9_-]{1,64}\z/

    class << self
      def build(wedding_code:, content_type:, load_test_run_id: nil)
        extension = extension_for(content_type)
        timestamp = Time.current.utc.strftime("%Y%m%d-%H%M%S")
        nonce = SecureRandom.hex(8)
        environment = Rails.env
        photos_path = photos_directory(load_test_run_id:)

        "#{environment}/#{wedding_code}/#{photos_path}/#{timestamp}-#{nonce}.#{extension}"
      end

      def sanitize_load_test_run_id(run_id)
        value = run_id.to_s.strip
        return nil if value.blank?
        return nil unless value.match?(LOAD_TEST_RUN_ID_FORMAT)

        value
      end

      def load_test_object_key_fragment(run_id = nil)
        sanitized = sanitize_load_test_run_id(run_id)
        if sanitized
          "/#{PHOTOS_DIRECTORY}/#{LOAD_TEST_DIRECTORY}/#{sanitized}/"
        else
          "/#{PHOTOS_DIRECTORY}/#{LOAD_TEST_DIRECTORY}/"
        end
      end

      private

      def photos_directory(load_test_run_id:)
        sanitized = sanitize_load_test_run_id(load_test_run_id)
        return PHOTOS_DIRECTORY if sanitized.blank?

        "#{PHOTOS_DIRECTORY}/#{LOAD_TEST_DIRECTORY}/#{sanitized}"
      end

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

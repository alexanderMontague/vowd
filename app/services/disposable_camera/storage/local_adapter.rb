require "fileutils"

module DisposableCamera
  module Storage
    # Stores objects on the local filesystem under Rails' public/ directory so the
    # static file server can serve them directly. Intended for development/test only.
    class LocalAdapter < Adapter
      PUBLIC_SUBPATH = "uploads/disposable_camera".freeze

      def upload!(io:, object_key:, content_type:)
        path = absolute_path_for(object_key)
        FileUtils.mkdir_p(path.dirname)
        io.rewind if io.respond_to?(:rewind)
        File.open(path, "wb") { |file| IO.copy_stream(io, file) }
      end

      def delete!(object_key:)
        FileUtils.rm_f(absolute_path_for(object_key))
      end

      def delete_objects!(object_keys:)
        Array(object_keys).filter_map(&:presence).each { |key| delete!(object_key: key) }
      end

      def public_url_for(object_key)
        "/#{PUBLIC_SUBPATH}/#{object_key}"
      end

      # Served same-origin, so the anchor's `download` attribute handles the
      # attachment behaviour; the URL itself is identical to the display URL.
      def download_url_for(object_key, filename: nil)
        public_url_for(object_key)
      end

      def download_object(object_key)
        File.open(absolute_path_for(object_key), "rb")
      end

      private

      def absolute_path_for(object_key)
        raise ArgumentError, "Unsafe object key: #{object_key.inspect}" if object_key.to_s.include?("..")

        Rails.public_path.join(PUBLIC_SUBPATH, object_key)
      end
    end
  end
end

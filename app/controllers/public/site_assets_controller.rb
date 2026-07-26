module Public
  class SiteAssetsController < Public::BaseController
    STREAM_CHUNK_SIZE = 64.kilobytes

    def save_the_date_mode_allowed?
      true
    end

    # Streams wedding site images/videos same-origin from private storage.
    def show
      object_key = Array(params[:object_key]).join("/")
      unless WeddingAssets::ObjectKeyBuilder.belongs_to_wedding?(object_key, current_wedding.id)
        raise ActionController::RoutingError, "Not Found"
      end

      body = DisposableCamera::StorageClient.download_object(object_key)
      content_type = WeddingAssets::ObjectKeyBuilder.content_type_for(object_key)

      response.headers["Cache-Control"] = "private, max-age=86400"

      if body.respond_to?(:path)
        path = body.path
        body.close
        send_file path, type: content_type, disposition: "inline", filename: File.basename(object_key)
      else
        response.headers["Content-Type"] = content_type
        self.response_body = StreamingBody.new(body, STREAM_CHUNK_SIZE)
      end
    rescue Errno::ENOENT, Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NotFound
      raise ActionController::RoutingError, "Not Found"
    end

    # Rack body that yields binary chunks without loading the whole object.
    class StreamingBody
      def initialize(io, chunk_size)
        @io = io
        @chunk_size = chunk_size
      end

      def each
        while (chunk = @io.read(@chunk_size))
          yield chunk
        end
      ensure
        close
      end

      def close
        return if @io.nil? || (@io.respond_to?(:closed?) && @io.closed?)

        @io.close if @io.respond_to?(:close)
      end
    end
  end
end

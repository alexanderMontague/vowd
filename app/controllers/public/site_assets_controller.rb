module Public
  class SiteAssetsController < Public::BaseController
    def save_the_date_mode_allowed?
      true
    end

    # Serves wedding site images/videos same-origin from private storage.
    def show
      body = nil
      object_key = Array(params[:object_key]).join("/")
      unless WeddingAssets::ObjectKeyBuilder.belongs_to_wedding?(object_key, current_wedding.id)
        raise ActionController::RoutingError, "Not Found"
      end

      body = DisposableCamera::StorageClient.download_object(object_key)
      content_type = WeddingAssets::ObjectKeyBuilder.content_type_for(object_key)

      response.headers["Cache-Control"] = "private, max-age=86400"

      if body.respond_to?(:path) && body.path.present?
        path = body.path
        body.close
        send_file path, type: content_type, disposition: "inline", filename: File.basename(object_key)
      else
        send_data body.read, type: content_type, disposition: "inline"
      end
    rescue Errno::ENOENT, Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NotFound
      raise ActionController::RoutingError, "Not Found"
    ensure
      close_body(body)
    end

    private

    def close_body(body)
      return if body.nil?
      return if body.respond_to?(:closed?) && body.closed?

      body.close if body.respond_to?(:close)
    end
  end
end

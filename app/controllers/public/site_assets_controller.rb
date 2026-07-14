module Public
  class SiteAssetsController < Public::BaseController
    def save_the_date_mode_allowed?
      true
    end

    # Streams wedding site images same-origin from private storage.
    def show
      object_key = Array(params[:object_key]).join("/")
      unless WeddingAssets::ObjectKeyBuilder.belongs_to_wedding?(object_key, current_wedding.id)
        raise ActionController::RoutingError, "Not Found"
      end

      body = DisposableCamera::StorageClient.download_object(object_key)
      content_type = WeddingAssets::ObjectKeyBuilder.content_type_for(object_key)

      response.headers["Cache-Control"] = "private, max-age=86400"
      send_data body.read, type: content_type, disposition: "inline"
    rescue Errno::ENOENT, Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NotFound
      raise ActionController::RoutingError, "Not Found"
    ensure
      body.close if body.respond_to?(:close)
    end
  end
end

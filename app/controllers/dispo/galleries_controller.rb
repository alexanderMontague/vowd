module Dispo
  class GalleriesController < ApplicationController
    layout "dispo"

    include WeddingConcern
    include SaveTheDateModeEnforcement

    DEFAULT_PER_PAGE = 48
    MAX_PER_PAGE = 96

    def index
      # render a 404 if the gallery is not visible
      raise ActionController::RoutingError, "Not Found" unless current_wedding.dispo_gallery_visible?

      scope = DisposablePhoto.where(wedding_id: current_wedding.id).recent_first

      @per_page = normalized_per_page
      @total_photos = scope.count
      @total_pages = (@total_photos.to_f / @per_page).ceil
      @page = normalized_page(@total_pages)

      @photos = scope.offset((@page - 1) * @per_page).limit(@per_page)
      @has_previous_page = @page > 1
      @has_next_page = @page < @total_pages
    end

    # Streams the original image same-origin so the browser can composite the
    # selected filter onto a canvas and export it (a cross-origin presigned URL
    # would taint the canvas and block export).
    def raw
      raise ActionController::RoutingError, "Not Found" unless current_wedding.dispo_gallery_visible?

      photo = DisposablePhoto.find_by!(id: params[:id], wedding_id: current_wedding.id)
      body = DisposableCamera::StorageClient.download_object(photo.object_key)

      response.headers["Cache-Control"] = "private, max-age=3600"
      send_data body.read, type: photo.content_type, disposition: "inline"
    ensure
      body.close if body.respond_to?(:close)
    end

    private

    def normalized_page(total_pages)
      requested_page = params[:page].to_i
      page = requested_page.positive? ? requested_page : 1
      page = [page, total_pages].min if total_pages.positive?
      page
    end

    def normalized_per_page
      requested_per_page = params[:per_page].to_i
      per_page = requested_per_page.positive? ? requested_per_page : DEFAULT_PER_PAGE

      [per_page, MAX_PER_PAGE].min
    end
  end
end

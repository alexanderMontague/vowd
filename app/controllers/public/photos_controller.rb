module Public
  class PhotosController < Public::BaseController
    guest_page :gallery

    DISPO_PREVIEW_LIMIT = 12

    def show
      load_dispo_photos if current_wedding.dispo_gallery_visible?
    end

    private

    def load_dispo_photos
      scope = DisposablePhoto.where(wedding_id: current_wedding.id).recent_first

      @dispo_total = scope.count
      @dispo_photos = scope.limit(DISPO_PREVIEW_LIMIT)
      @dispo_has_more = @dispo_total > DISPO_PREVIEW_LIMIT
    end
  end
end

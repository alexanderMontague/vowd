module Admin
  class ThemesController < Admin::BaseController
    include ThemePreviewing
    include ThemeFormParams

    def show
      @saved_theme = current_wedding.site_theme
      # The editor opens on whatever the admin was last looking at, so navigating away
      # from a half-finished palette and back does not lose it.
      @theme = theme_preview_active? ? WeddingTheme.new(theme_preview_config) : @saved_theme
      @unsaved_changes = @theme != @saved_theme
    end

    def update
      theme = submitted_theme

      if theme.nil?
        @saved_theme = current_wedding.site_theme
        @theme = @saved_theme
        flash.now[:alert] = "Pick one of the available themes."
        return render :show, status: :unprocessable_content
      end

      current_wedding.update!(theme: theme.to_h)
      clear_theme_preview

      redirect_to admin_theme_path, notice: "Theme saved."
    end
  end
end

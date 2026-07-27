module Admin
  class ThemesController < Admin::BaseController
    include ThemePreviewing
    include ThemeFormParams
    include WeddingContentParams

    before_action :require_configured_wedding
    before_action :ensure_section

    def show
      return if performed?

      @wedding = current_wedding
      prepare_theme_editor if look_section?
      prepare_content_library unless look_section?
    end

    def update
      return if performed?

      @wedding = current_wedding

      if look_section?
        update_theme
      else
        update_content
      end
    end

    private

    def require_configured_wedding
      return if current_wedding.configured?

      redirect_to admin_website_path, alert: "Finish wedding setup before editing the site."
    end

    def ensure_section
      if params[:section].blank?
        redirect_to admin_theme_section_path(section: ThemeSections::DEFAULT_KEY)
        return
      end

      @section = ThemeSections.find(params[:section])
      return if @section

      redirect_to admin_theme_section_path(section: ThemeSections::DEFAULT_KEY)
    end

    def look_section?
      @section.key == "look"
    end

    def prepare_theme_editor
      @saved_theme = current_wedding.site_theme
      @theme = theme_preview_active? ? WeddingTheme.new(theme_preview_config) : @saved_theme
      @unsaved_changes = @theme != @saved_theme
    end

    def prepare_content_library
      @library_assets = current_wedding.wedding_assets.images.ordered.to_a
      @library_index = @library_assets.index_by { |asset| asset.id.to_s }
    end

    def update_theme
      theme = submitted_theme

      if theme.nil?
        prepare_theme_editor
        flash.now[:alert] = "Pick one of the available themes."
        return render :show, status: :unprocessable_content
      end

      current_wedding.update!(theme: theme.to_h)
      clear_theme_preview

      redirect_to admin_theme_section_path(section: @section.key), notice: "Theme saved."
    end

    def update_content
      attrs = build_wedding_attributes

      if @wedding.update(attrs)
        redirect_to admin_theme_section_path(section: @section.key),
                    notice: "Page content saved."
      else
        prepare_content_library
        flash.now[:alert] = @wedding.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end
  end
end

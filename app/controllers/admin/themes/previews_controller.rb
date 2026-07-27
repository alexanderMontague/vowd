module Admin
  module Themes
    # Holds the theme editor's unsaved state for the guest site to read, so the preview
    # iframe can be clicked through page to page without the draft evaporating.
    class PreviewsController < Admin::BaseController
      include ThemePreviewing
      include ThemeFormParams

      def create
        persist_preview!
      end

      # Same body as create: the editor may POST the Save form's fields here, and
      # Rails method-override turns that into PATCH when `_method` is present.
      alias_method :update, :create

      def destroy
        clear_theme_preview

        redirect_to admin_theme_section_path(section: ThemeSections::DEFAULT_KEY), notice: "Preview discarded."
      end

      private

      def persist_preview!
        theme = submitted_theme
        return head :unprocessable_content if theme.nil?

        store_theme_preview(theme)
        head :no_content
      end
    end
  end
end

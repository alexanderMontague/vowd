# Shared reading of the theme editor form, used by both saving and previewing so the
# two can never interpret the same submission differently.
module ThemeFormParams
  extend ActiveSupport::Concern

  private

  # A normalised theme, or nil when the submission names a theme we do not ship.
  #
  # Only the theme key is validated. Colours and page toggles are normalised instead:
  # the form only offers legal values, and quietly correcting a stray one is more
  # useful to an admin than refusing the whole save.
  def submitted_theme
    permitted = theme_params
    return nil if SiteThemes.find(permitted[:key]).nil?

    WeddingTheme.new(permitted.to_h)
  end

  def theme_params
    params.require(:theme).permit(
      :key,
      :font,
      colors: SiteThemes::COLOR_KEYS,
      pages: SitePages.toggleable_keys
    )
  rescue ActionController::ParameterMissing
    ActionController::Parameters.new.permit
  end
end

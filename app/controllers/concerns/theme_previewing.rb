# Carries an admin's unsaved theme edits into the guest site so the admin preview
# iframe can be clicked through exactly like the real thing, with no query strings to
# thread through every link.
#
# The draft lives in the session, which admin and the guest site share because both
# run on the wedding's slug subdomain. It is keyed to a wedding and only honoured
# while an admin session is present, so a stale draft can never leak to a visitor.
module ThemePreviewing
  extend ActiveSupport::Concern

  SESSION_KEY = "theme_preview".freeze

  private

  def theme_preview_config
    draft = theme_preview_draft
    return nil if draft.blank?

    draft["theme"]
  end

  def theme_preview_active?
    theme_preview_config.present?
  end

  def store_theme_preview(theme)
    session[SESSION_KEY] = { "wedding_id" => current_wedding.id, "theme" => theme.to_h }
  end

  def clear_theme_preview
    session.delete(SESSION_KEY)
  end

  def theme_preview_draft
    return nil if session[:admin_id].blank?

    draft = session[SESSION_KEY]
    return nil if draft.blank?
    return nil unless draft["wedding_id"] == current_wedding&.id

    draft
  end
end

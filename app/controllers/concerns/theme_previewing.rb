# Carries an admin's unsaved theme edits into the guest site so the admin preview
# iframe can be clicked through exactly like the real thing, with no query strings to
# thread through every link.
#
# The draft lives in the session, which admin and the guest site share because both
# run on the wedding's slug subdomain. It is keyed to a wedding and only honoured
# while an admin session is present — and only for iframe embeds — so a top-level
# public visit never inherits draft fonts/colours from an open Theme editor.
module ThemePreviewing
  extend ActiveSupport::Concern

  SESSION_KEY = "theme_preview".freeze

  private

  def theme_preview_config
    draft = theme_preview_draft
    return nil if draft.blank?

    # Admin Theme chrome always reads the draft so Look & feel can stay unsaved.
    # Guest pages only apply it inside the preview iframe — never on a top-level
    # public tab open beside admin (that was leaking draft fonts/colours).
    return draft["theme"] if admin_host_path?
    return nil unless preview_embed_request?

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

  def admin_host_path?
    request.path.start_with?("/admin")
  end

  # Theme iframe (and only that) sends Sec-Fetch-Dest: iframe on full page loads.
  def preview_embed_request?
    request.headers["Sec-Fetch-Dest"] == "iframe"
  end
end
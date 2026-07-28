# Marks the guest site as being edited inside the admin Theme iframe.
#
# The flag lives in the session (shared across the wedding host), keyed to the
# current wedding and only honoured while an admin is signed in. Cleared when
# the admin leaves Theme for another admin section.
#
# Hotspots must never appear on a normal top-level visit — even for a signed-in
# admin browsing the public site. We require Sec-Fetch-Dest: iframe so only the
# Theme preview embed gets editor chrome. Preview navigations use full page loads
# (turbo disabled in editor mode), which keep that iframe destination header.
module SiteEditor
  extend ActiveSupport::Concern

  SESSION_KEY = "site_editor".freeze

  included do
    helper_method :site_editor_active? if respond_to?(:helper_method)
  end

  private

  def site_editor_active?
    return false if session[:admin_id].blank?
    return false unless session[SESSION_KEY] == current_wedding&.id

    request.headers["Sec-Fetch-Dest"] == "iframe"
  end

  def activate_site_editor!
    session[SESSION_KEY] = current_wedding.id
  end

  def clear_site_editor!
    session.delete(SESSION_KEY)
  end
end

# Marks the guest site as being edited inside the admin Theme iframe.
#
# The flag lives in the session (shared across the wedding host), keyed to the
# current wedding and only honoured while an admin is signed in. Cleared when
# the admin leaves Theme for another admin section.
#
# Hotspots must never appear on a normal top-level visit — even for a signed-in
# admin browsing the public site. We require Sec-Fetch-Dest: iframe so only the
# Theme preview embed gets editor chrome.
#
# Turbo is disabled for the whole site_editor session (iframe + any top-level
# public tab open beside Theme). Full document loads keep Sec-Fetch-Dest:
# iframe on preview navigations so the parent can sync the admin URL from the
# iframe's load events.
module SiteEditor
  extend ActiveSupport::Concern

  SESSION_KEY = "site_editor".freeze

  included do
    helper_method :site_editor_active?, :site_editor_session? if respond_to?(:helper_method)
  end

  private

  def site_editor_session?
    session[:admin_id].present? && session[SESSION_KEY] == current_wedding&.id
  end

  def site_editor_active?
    site_editor_session? && request.headers["Sec-Fetch-Dest"] == "iframe"
  end

  def activate_site_editor!
    session[SESSION_KEY] = current_wedding.id
  end

  def clear_site_editor!
    session.delete(SESSION_KEY)
  end
end

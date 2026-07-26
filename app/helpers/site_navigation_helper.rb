# Turns `SitePages` definitions into links. Route helpers live here rather than in
# the registry so the registry stays a plain data description of the site.
module SiteNavigationHelper
  def site_page_path(page)
    public_send(page.path_helper)
  end

  # True for the page itself and anything nested under it, so /rsvp/:code still
  # highlights RSVP. The root path is matched exactly, since every path starts with it.
  def site_page_current?(page)
    path = site_page_path(page)
    return request.path == path if path == "/"

    request.path == path || request.path.start_with?("#{path}/")
  end

  def site_page_link(page, css_class: "wedding-nav-link")
    link_to site_page_path(page),
            class: class_names(css_class, { active: site_page_current?(page) }) do
      page.label
    end
  end
end

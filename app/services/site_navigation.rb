# Decides which guest pages a wedding site actually exposes, and in what order.
#
# Three switches have to agree, and they answer different questions:
#   - the theme's page toggle: does the couple want this page at all?
#   - the page's feature flag: does the site's schedule allow it right now?
#   - save the date mode: is the whole site collapsed to one page?
#
# Every caller (navigation, controller gating, the admin preview) goes through here
# so the answer cannot drift between the link and the page it points at.
class SiteNavigation
  def initialize(wedding:, theme:, preview: false)
    @wedding = wedding
    @theme = theme
    @preview = preview
  end

  attr_reader :wedding, :theme

  # An admin previewing an unsaved theme is judging the theme, not the schedule, so
  # previews ignore the time-based switches and show whatever the theme allows.
  def preview?
    @preview
  end

  def save_the_date_only?
    return false if preview?

    wedding.save_the_date_mode?
  end

  def visible?(page_key)
    page = SitePages.find(page_key)
    return false if page.nil?
    return page.key == "save_the_date" if save_the_date_only?
    return false unless theme.page_enabled?(page.key)

    feature_flag_allows?(page)
  end

  # Visible pages in registry order, ready to render as navigation links.
  def pages
    SitePages.definitions.select { |page| visible?(page.key) }
  end

  # Where the site logo points. In save the date mode the homepage is unreachable, so
  # the logo has to lead somewhere that exists.
  def landing_page
    save_the_date_only? ? SitePages.find("save_the_date") : SitePages.find("home")
  end

  private

  def feature_flag_allows?(page)
    return true if page.feature_flag.nil?
    return true if preview?

    wedding.feature_flag(page.feature_flag)
  end
end

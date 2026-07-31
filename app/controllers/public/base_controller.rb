module Public
  class BaseController < ApplicationController
    include WeddingConcern
    include GuestSiteAvailability
    # Ordered so save the date mode redirects before the theme gate can 404: a
    # collapsed site should send guests to the one page that exists, not refuse them.
    include SaveTheDateModeEnforcement
    include SiteThemeRendering

    layout "public"

    # Prepended so it runs ahead of every other filter: theme resolution and save the
    # date enforcement both read `current_wedding`. GuestSiteAvailability is also
    # prepended (via the concern); this line is registered after so require runs first.
    prepend_before_action :require_wedding!

    private

    # An admin previewing an unsaved theme needs to reach every page the theme
    # defines, including the ones save the date mode would otherwise collapse.
    def save_the_date_mode_enforced?
      site_navigation.save_the_date_only?
    end
  end
end

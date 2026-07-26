module Public
  class BaseController < ApplicationController
    include WeddingConcern
    # Ordered so save the date mode redirects before the theme gate can 404: a
    # collapsed site should send guests to the one page that exists, not refuse them.
    include SaveTheDateModeEnforcement
    include SiteThemeRendering

    layout "public"

    # Prepended so it runs ahead of every other filter: theme resolution and save the
    # date enforcement both read `current_wedding`.
    prepend_before_action :require_wedding!

    private

    # An admin previewing an unsaved theme needs to reach every page the theme
    # defines, including the ones save the date mode would otherwise collapse.
    def save_the_date_mode_enforced?
      site_navigation.save_the_date_only?
    end
  end
end

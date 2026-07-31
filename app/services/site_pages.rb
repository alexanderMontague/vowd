# The guest-facing pages a wedding site can expose. This is the single source of
# truth for page identity: themes toggle these keys, navigation renders them, and
# controllers gate on them.
#
# `feature_flag` names an existing flag that must also be on for the page to show,
# which is how a theme toggle layers on top of the flag system rather than fighting
# it. `toggleable: false` means the page is structural and always present.
class SitePages
  Page = Data.define(:key, :label, :description, :path_helper, :feature_flag, :toggleable)

  DEFINITIONS = [
    Page.new(
      key: "home",
      label: "Home",
      description: "The landing page. Always visible.",
      path_helper: :root_path,
      feature_flag: nil,
      toggleable: false
    ),
    Page.new(
      key: "gallery",
      label: "Photos",
      description: "Curated photo sections, plus the disposable camera album when enabled.",
      path_helper: :public_photos_path,
      feature_flag: nil,
      toggleable: true
    ),
    Page.new(
      key: "wedding_party",
      label: "Wedding Party",
      description: "Bridesmaids and groomsmen with photos and roles.",
      path_helper: :public_wedding_party_path,
      feature_flag: nil,
      toggleable: true
    ),
    Page.new(
      key: "faq",
      label: "FAQ",
      description: "Questions and answers for guests.",
      path_helper: :public_faq_path,
      feature_flag: nil,
      toggleable: true
    ),
    Page.new(
      key: "save_the_date",
      label: "Save the Date",
      description: "Announcement page with countdown, calendar link and signup form.",
      path_helper: :public_save_the_date_path,
      feature_flag: nil,
      toggleable: true
    ),
    Page.new(
      key: "rsvp",
      label: "RSVP",
      description: "Guest lookup and RSVP form.",
      path_helper: :public_rsvp_lookup_path,
      feature_flag: nil,
      toggleable: true
    )
  ].freeze

  class << self
    def definitions
      DEFINITIONS
    end

    def find(key)
      DEFINITIONS.find { |page| page.key == key.to_s }
    end

    def keys
      DEFINITIONS.map(&:key)
    end

    def toggleable
      DEFINITIONS.select(&:toggleable)
    end

    def toggleable_keys
      toggleable.map(&:key)
    end

    def all_enabled
      keys.index_with(true)
    end
  end
end

# Sections of the Theme site editor. Each maps to a URL segment, a left-rail
# control panel, and the guest page the preview iframe should open on.
class ThemeSections
  Section = Data.define(:key, :label, :group, :preview_page, :content_keys)

  DEFINITIONS = [
    Section.new(
      key: "look",
      label: "Look & feel",
      group: :design,
      preview_page: "home",
      content_keys: []
    ),
    Section.new(
      key: "home",
      label: "Home",
      group: :pages,
      preview_page: "home",
      content_keys: %w[hero story photos_page placements]
    ),
    Section.new(
      key: "photos",
      label: "Photos",
      group: :pages,
      preview_page: "gallery",
      content_keys: %w[photos_page placements]
    ),
    Section.new(
      key: "save_the_date",
      label: "Save the Date",
      group: :pages,
      preview_page: "save_the_date",
      content_keys: %w[save_the_date_copy placements]
    ),
    Section.new(
      key: "rsvp",
      label: "RSVP",
      group: :pages,
      preview_page: "rsvp",
      content_keys: %w[rsvp_copy placements]
    ),
    Section.new(
      key: "faq",
      label: "FAQ",
      group: :pages,
      preview_page: "faq",
      content_keys: %w[faq]
    ),
    Section.new(
      key: "wedding_party",
      label: "Wedding party",
      group: :pages,
      preview_page: "wedding_party",
      content_keys: %w[wedding_party]
    )
  ].freeze

  GROUP_LABELS = {
    design: "Design",
    pages: "Pages"
  }.freeze

  DEFAULT_KEY = "look".freeze

  class << self
    def definitions
      DEFINITIONS
    end

    def find(key)
      DEFINITIONS.find { |section| section.key == key.to_s }
    end

    def keys
      DEFINITIONS.map(&:key)
    end

    def default
      find(DEFAULT_KEY)
    end

    def group_label(group)
      GROUP_LABELS.fetch(group.to_sym, group.to_s.titleize)
    end

    def by_group
      DEFINITIONS.group_by(&:group)
    end

    def constraint
      Regexp.union(keys)
    end
  end
end

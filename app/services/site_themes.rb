# The available wedding website themes. A theme owns the layout and view treatment
# of the guest site; the colours, fonts and page toggles it declares here are only
# starting points that each wedding can override.
#
# Views for a theme live in `app/views/themes/<key>/`, which is prepended to the
# public view path at request time. Anything a theme does not override falls back to
# the shared `app/views/public/` templates, so a theme can ship incrementally.
class SiteThemes
  Theme = Data.define(
    :key,
    :name,
    :tagline,
    :description,
    :default_colors,
    :default_font,
    :default_pages
  ) do
    def view_root
      Rails.root.join("app/views/themes", key)
    end

    def views?
      view_root.directory?
    end

    def color_default(color_key)
      default_colors.fetch(color_key.to_s)
    end
  end

  # Every theme declares the same colour roles so a wedding's palette survives a
  # theme switch.
  COLOR_ROLES = [
    { key: "primary", label: "Primary", hint: "Buttons, links and the active navigation state." },
    { key: "accent", label: "Accent", hint: "Ornament, dividers, frames and small emphasis text." },
    { key: "ink", label: "Text", hint: "Headings, body copy and the dark footer." },
    { key: "surface", label: "Background", hint: "The main page background." },
    { key: "surface_alt", label: "Alternate background", hint: "Banded sections and cards." }
  ].freeze

  COLOR_KEYS = COLOR_ROLES.map { |role| role[:key] }.freeze

  DEFINITIONS = [
    Theme.new(
      key: "classic",
      name: "Classic Invitation",
      tagline: "Engraved stationery, brought online",
      description: "Centred type, botanical corners and a lace invitation frame. Calm, formal and " \
                   "photo-light.",
      default_colors: {
        "primary" => "#292524",
        "accent" => "#C89B7B",
        "ink" => "#292524",
        "surface" => "#FAFAF9",
        "surface_alt" => "#F5F5F4"
      },
      default_font: "classic",
      default_pages: SitePages.all_enabled
    ),
    Theme.new(
      key: "parallax",
      name: "Romance in Motion",
      tagline: "Layered ornament that drifts as you scroll",
      description: "Full-bleed hero framed by drapes and columns, with ornament and photography " \
                   "that parallax against the scroll. The most decorative option.",
      default_colors: {
        "primary" => "#8B7A5E",
        "accent" => "#C0A98A",
        "ink" => "#3A3C38",
        "surface" => "#FAF9F6",
        "surface_alt" => "#FFFFFF"
      },
      default_font: "classic",
      default_pages: SitePages.all_enabled
    ),
    Theme.new(
      key: "editorial",
      name: "Editorial",
      tagline: "A wedding issue, not a wedding card",
      description: "Oversized display type, numbered sections and full-bleed photography on an " \
                   "asymmetric grid. No ornament at all.",
      default_colors: {
        "primary" => "#1B1A17",
        "accent" => "#B24A2E",
        "ink" => "#1B1A17",
        "surface" => "#F6F4EF",
        "surface_alt" => "#FFFFFF"
      },
      default_font: "editorial",
      default_pages: SitePages.all_enabled
    ),
    Theme.new(
      key: "garden",
      name: "Sage Garden",
      tagline: "Quiet foliage on soft green paper",
      description: "Pressed-flower stationery: climbing vines, wreath portraits, terracotta " \
                   "planters, and soft sage washes. Built for garden ceremonies.",
      default_colors: {
        "primary" => "#4F6B4E",
        "accent" => "#8FA386",
        "ink" => "#2A352A",
        "surface" => "#F3F5F0",
        "surface_alt" => "#E8EDE4"
      },
      default_font: "refined",
      default_pages: SitePages.all_enabled
    ),
    Theme.new(
      key: "atelier",
      name: "Atelier Deco",
      tagline: "Geometric gilding for evening weddings",
      description: "Art deco ballroom: sunburst fans, diamond photo plates, geometric pedestals, " \
                   "and gold-ruled pages. Formal without feeling stiff.",
      default_colors: {
        "primary" => "#1A2744",
        "accent" => "#C6A15B",
        "ink" => "#1A2744",
        "surface" => "#F7F3EA",
        "surface_alt" => "#FFFFFF"
      },
      default_font: "modern",
      default_pages: SitePages.all_enabled
    ),
    Theme.new(
      key: "riviera",
      name: "Riviera",
      tagline: "Sun-washed azure and citrus light",
      description: "Amalfi-coast postcards: ceramic frames, citrus garlands, amphora photos, and " \
                   "sun-washed azure. Bright Mediterranean calm.",
      default_colors: {
        "primary" => "#2F5D7A",
        "accent" => "#D4A35C",
        "ink" => "#243447",
        "surface" => "#FBF8F2",
        "surface_alt" => "#EEF4F7"
      },
      default_font: "airy",
      default_pages: SitePages.all_enabled
    )
  ].freeze

  DEFAULT_KEY = "classic".freeze

  class << self
    def definitions
      DEFINITIONS
    end

    def find(key)
      DEFINITIONS.find { |theme| theme.key == key.to_s }
    end

    def fetch(key)
      find(key) || default
    end

    def default
      find(DEFAULT_KEY) || DEFINITIONS.first
    end

    def keys
      DEFINITIONS.map(&:key)
    end
  end
end

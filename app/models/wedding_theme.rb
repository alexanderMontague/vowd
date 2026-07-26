# A wedding's resolved website theme: the chosen theme plus its colour, font and
# page-visibility overrides, normalised against the registries so callers never have
# to defend against a stale theme key or a half-typed hex value.
#
# Instances are immutable and cheap; build one per request from `wedding.theme` (or
# from an admin's unsaved preview draft) and read from it everywhere.
class WeddingTheme
  CSS_VARIABLE_PREFIX = "--theme-".freeze

  def self.for(wedding, override: nil)
    new(override.presence || wedding&.theme)
  end

  def initialize(config = nil)
    source = normalize_source(config)

    @theme = SiteThemes.fetch(source["key"])
    @font = SiteFonts.fetch(source["font"], fallback: @theme.default_font)
    @colors = resolve_colors(source["colors"])
    @pages = resolve_pages(source["pages"])

    freeze
  end

  attr_reader :theme, :font, :colors, :pages

  delegate :key, :name, :tagline, :description, :view_root, :views?, to: :theme

  def color(role)
    colors[role.to_s]
  end

  def page_enabled?(page_key)
    pages.fetch(page_key.to_s, false)
  end

  # Runtime overrides for the design tokens the stylesheet is built against. Only the
  # roles a wedding actually chooses are emitted; everything else is derived from
  # these in CSS so a palette change needs no rebuild.
  def css_variables
    {
      "primary" => color("primary"),
      "primary-contrast" => ThemeColor.legible_on(color("primary")),
      "accent" => color("accent"),
      "accent-contrast" => ThemeColor.legible_on(color("accent")),
      "ink" => color("ink"),
      "ink-contrast" => ThemeColor.legible_on(color("ink")),
      "surface" => color("surface"),
      "surface-alt" => color("surface_alt"),
      "font-display" => font.display_family,
      "font-body" => font.body_family
    }.transform_keys { |name| "#{CSS_VARIABLE_PREFIX}#{name}" }
  end

  def style_attribute
    css_variables.map { |name, value| "#{name}: #{value}" }.join("; ")
  end

  def fonts_href
    font.google_href
  end

  # The persistable shape. Written back verbatim so a round trip through the admin
  # form cannot silently drop a role or leave an invalid value behind.
  def to_h
    {
      "key" => key,
      "font" => font.key,
      "colors" => colors,
      "pages" => pages
    }
  end

  def ==(other)
    other.is_a?(WeddingTheme) && other.to_h == to_h
  end
  alias eql? ==

  def hash
    to_h.hash
  end

  private

  def normalize_source(config)
    return {} if config.blank?

    config.to_h.deep_stringify_keys
  end

  def resolve_colors(overrides)
    given = (overrides || {}).to_h

    SiteThemes::COLOR_KEYS.index_with do |role|
      ThemeColor.normalize(given[role], fallback: theme.color_default(role))
    end.freeze
  end

  # Structural pages ignore their stored value: nothing should be able to hide the
  # homepage.
  def resolve_pages(overrides)
    given = (overrides || {}).to_h
    caster = ActiveModel::Type::Boolean.new

    SitePages.definitions.to_h do |page|
      enabled = if page.toggleable
                  given.key?(page.key) ? caster.cast(given[page.key]) : theme.default_pages.fetch(page.key, true)
                else
                  true
                end

      [page.key, !!enabled]
    end.freeze
  end
end

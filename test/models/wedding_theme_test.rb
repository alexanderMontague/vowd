require "test_helper"

class WeddingThemeTest < ActiveSupport::TestCase
  test "falls back to the default theme when no config is stored" do
    theme = WeddingTheme.new(nil)

    assert_equal SiteThemes::DEFAULT_KEY, theme.key
    assert_equal SiteThemes.default.default_colors["primary"], theme.color("primary")
  end

  test "falls back to the default theme when the stored key is not one we ship" do
    theme = WeddingTheme.new("key" => "art-deco-from-2019")

    assert_equal SiteThemes::DEFAULT_KEY, theme.key
  end

  test "inherits unset colours from the chosen theme rather than the default theme" do
    theme = WeddingTheme.new("key" => "editorial", "colors" => { "primary" => "#123456" })

    assert_equal "#123456", theme.color("primary")
    assert_equal SiteThemes.find("editorial").default_colors["accent"], theme.color("accent")
  end

  test "normalises shorthand hex and rejects unparseable colours" do
    theme = WeddingTheme.new("colors" => { "primary" => "#abc", "accent" => "cornflower" })

    assert_equal "#AABBCC", theme.color("primary")
    assert_equal SiteThemes.default.default_colors["accent"], theme.color("accent")
  end

  test "falls back to the theme's own font when the stored pairing is unknown" do
    theme = WeddingTheme.new("key" => "editorial", "font" => "papyrus")

    assert_equal SiteThemes.find("editorial").default_font, theme.font.key
  end

  test "casts page toggles and never lets a structural page be switched off" do
    theme = WeddingTheme.new("pages" => { "faq" => "0", "gallery" => "1", "home" => "0" })

    assert_not theme.page_enabled?("faq")
    assert theme.page_enabled?("gallery")
    assert theme.page_enabled?("home"), "the homepage is structural and cannot be hidden"
  end

  test "unknown pages are not enabled" do
    assert_not WeddingTheme.new.page_enabled?("registry")
  end

  test "css variables cover every authored token and pick legible foregrounds" do
    theme = WeddingTheme.new("colors" => { "primary" => "#FFFFFF", "ink" => "#000000" })
    variables = theme.css_variables

    %w[primary primary-contrast accent accent-contrast ink ink-contrast surface surface-alt
       font-display font-body].each do |name|
      assert variables.key?("--theme-#{name}"), "expected --theme-#{name} to be emitted"
    end

    assert_equal ThemeColor::DARK_FOREGROUND, variables["--theme-primary-contrast"]
    assert_equal ThemeColor::LIGHT_FOREGROUND, variables["--theme-ink-contrast"]
  end

  test "round trips through to_h without losing or inventing values" do
    original = WeddingTheme.new("key" => "parallax", "font" => "modern",
                                "colors" => { "primary" => "#101010" },
                                "pages" => { "faq" => false })

    assert_equal original, WeddingTheme.new(original.to_h)
  end

  test "prefers an override over the wedding's stored theme" do
    wedding = create_wedding(theme: { "key" => "classic" })

    assert_equal "editorial", WeddingTheme.for(wedding, override: { "key" => "editorial" }).key
    assert_equal "classic", WeddingTheme.for(wedding).key
  end

  test "every shipped theme declares a colour for every role and a real font" do
    SiteThemes.definitions.each do |theme|
      SiteThemes::COLOR_KEYS.each do |role|
        assert ThemeColor.valid?(theme.default_colors[role]),
               "#{theme.key} is missing a valid #{role} colour"
      end

      assert SiteFonts.find(theme.default_font), "#{theme.key} names an unknown font pairing"
    end
  end
end

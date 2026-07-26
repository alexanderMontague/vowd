require "test_helper"

class SiteNavigationTest < ActiveSupport::TestCase
  setup do
    @wedding = create_wedding(rsvp_deadline: Date.current + 30)
  end

  test "a page needs both the theme toggle and the feature flag" do
    force_flag("rsvp_visible", true)

    assert navigation(pages: { "rsvp" => true }).visible?("rsvp")
    assert_not navigation(pages: { "rsvp" => false }).visible?("rsvp"),
               "the theme toggle alone should be able to hide a page"

    force_flag("rsvp_visible", false)

    assert_not navigation(pages: { "rsvp" => true }).visible?("rsvp"),
               "the feature flag alone should be able to hide a page"
  end

  test "pages without a feature flag answer to the theme toggle only" do
    assert navigation(pages: { "faq" => true }).visible?("faq")
    assert_not navigation(pages: { "faq" => false }).visible?("faq")
  end

  test "save the date mode collapses the site to one page" do
    force_flag("save_the_date_mode", true)
    nav = navigation

    assert nav.save_the_date_only?
    assert_equal ["save_the_date"], nav.pages.map(&:key)
    assert_equal "save_the_date", nav.landing_page.key
  end

  test "previewing ignores the schedule but still honours the theme" do
    force_flag("save_the_date_mode", true)
    force_flag("rsvp_visible", false)

    nav = navigation(pages: { "rsvp" => true, "faq" => false }, preview: true)

    assert_not nav.save_the_date_only?
    assert nav.visible?("rsvp"), "a preview should reach pages the schedule hides"
    assert_not nav.visible?("faq"), "a preview should still respect the theme's own toggles"
    assert_equal "home", nav.landing_page.key
  end

  test "unknown pages are never visible" do
    assert_not navigation.visible?("registry")
  end

  test "pages come back in registry order" do
    visible = navigation.pages.map(&:key)

    assert_equal visible, SitePages.keys & visible
  end

  test "the homepage cannot be toggled away" do
    assert navigation(pages: { "home" => false }).visible?("home")
  end

  private

  def navigation(pages: {}, preview: false)
    SiteNavigation.new(
      wedding: @wedding,
      theme: WeddingTheme.new("pages" => pages),
      preview: preview
    )
  end

  def force_flag(key, value)
    record = WeddingMetadata.find_or_initialize_by(wedding_id: @wedding.id, key: key)
    record.update!(value: value.to_s)
    @wedding.reload
  end
end

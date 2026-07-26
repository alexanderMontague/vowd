require "test_helper"

class Public::SiteThemeTest < ActionDispatch::IntegrationTest
  setup do
    @wedding = create_wedding
    host_wedding!(@wedding)
  end

  test "renders the chosen theme's key, palette and fonts into the document" do
    @wedding.update!(theme: { "key" => "editorial", "colors" => { "primary" => "#123456" } })

    get root_path

    assert_response :success
    assert_select "html[data-theme='editorial']"
    assert_includes response.body, "--theme-primary: #123456"
    assert_select "link[data-theme-fonts][href=?]", SiteFonts.fetch("editorial").google_href
  end

  test "falls back to the default theme when the stored key is stale" do
    @wedding.update!(theme: { "key" => "gone" })

    get root_path

    assert_response :success
    assert_select "html[data-theme='#{SiteThemes::DEFAULT_KEY}']"
  end

  test "each shipped theme renders every guest page" do
    SiteThemes.keys.each do |key|
      @wedding.update!(theme: { "key" => key })

      SitePages.definitions.each do |page|
        get send(page.path_helper)

        assert_response :success, "#{key} theme failed to render the #{page.key} page"
      end
    end
  end

  # A theme's view directory is found by convention, so a rename would silently fall
  # back to the shared templates on every page. These assert the override resolves.
  test "the parallax theme's own templates are the ones that render" do
    @wedding.update!(theme: { "key" => "parallax" })

    get root_path
    assert_select ".parallax-hero"
    assert_select ".parallax-ornament"

    get public_faq_path
    assert_select ".parallax-section"
  end

  test "the editorial theme's own templates are the ones that render" do
    @wedding.update!(
      theme: { "key" => "editorial" },
      wedding_party: @wedding.wedding_party.merge(
        "bridesmaids" => [{ "name" => "Nora", "role" => "Maid of Honour" }]
      )
    )

    get root_path
    assert_select ".editorial-cover"
    assert_select ".editorial-marker__number"

    get public_wedding_party_path
    assert_select ".editorial-contributors .editorial-contributor__name", text: "Nora"
  end

  test "a theme's templates do not leak into another theme" do
    @wedding.update!(theme: { "key" => "classic" })

    get root_path

    assert_select ".parallax-hero", count: 0
    assert_select ".editorial-cover", count: 0
    assert_select ".wedding-hero"
  end

  test "the parallax theme's decorative assets all resolve" do
    @wedding.update!(theme: { "key" => "parallax" })

    get root_path

    sources = css_select("[style*=parallax-ornament-src]").map { |node| node["style"] }
    assert_predicate sources, :any?, "expected the homepage to place some ornament"
    sources.each { |style| assert_match %r{/assets/themes/parallax/}, style }
  end

  test "navigation only links to pages the theme enables" do
    @wedding.update!(theme: { "pages" => { "faq" => false } })

    get root_path

    assert_select "nav a[href='#{public_faq_path}']", count: 0
    assert_select "nav a[href='#{public_wedding_party_path}']"
  end

  test "a page the theme disables is not reachable" do
    @wedding.update!(theme: { "pages" => { "faq" => false } })

    get public_faq_path

    assert_response :not_found
  end

  test "the RSVP page explains itself instead of disappearing" do
    @wedding.update!(theme: { "pages" => { "rsvp" => false } })

    get public_rsvp_lookup_path

    assert_response :not_found
    assert_select "nav a[href='#{public_rsvp_lookup_path}']", count: 0
  end

  test "the footer renders once per page rather than per template" do
    get root_path

    assert_select "footer.wedding-footer", count: 1
  end

  test "the invitation pages opt out of the site footer" do
    get public_save_the_date_path

    assert_select "footer.wedding-footer", count: 0
  end

  test "a visitor never sees an admin's preview draft" do
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)
    post admin_theme_preview_path, params: { theme: { key: "parallax" } }

    get root_path
    assert_select "html[data-theme='parallax']", 1, "the admin who owns the draft should see it"
    assert_select ".theme-preview-banner"

    delete admin_logout_path

    get root_path
    assert_select "html[data-theme='#{SiteThemes::DEFAULT_KEY}']"
    assert_select ".theme-preview-banner", count: 0
  end

  test "a preview reaches pages the schedule would hide" do
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)
    post admin_theme_preview_path, params: { theme: { key: "classic" } }
    WeddingMetadata.create!(wedding_id: @wedding.id, key: "save_the_date_mode", value: "true")

    get public_faq_path
    assert_response :success, "save the date mode should not collapse an admin preview"
  end

  test "save the date mode still collapses the site for guests" do
    WeddingMetadata.create!(wedding_id: @wedding.id, key: "save_the_date_mode", value: "true")

    get public_faq_path

    assert_redirected_to public_save_the_date_path
  end
end

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

  test "guests never see site editor hotspots" do
    get root_path

    assert_response :success
    assert_select "[data-site-editor-target='hotspot']", count: 0
    assert_no_match(/data-controller=["']site-editor["']/, response.body)
  end

  test "an admin outside the theme editor never sees hotspots" do
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)

    get root_path

    assert_response :success
    assert_select "[data-site-editor-target='hotspot']", count: 0
  end

  test "a signed-in admin browsing the public site top-level never sees hotspots" do
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)
    get admin_theme_section_path(section: "home")

    get root_path

    assert_response :success
    assert_select "[data-controller='site-editor']", count: 0
    assert_select "[data-site-editor-target='hotspot']", count: 0
    # Turbo stays off for the editor session so iframe nav keeps full loads,
    # but hotspots still require Sec-Fetch-Dest: iframe.
    assert_select "meta[name='turbo'][content='false']"
    assert_select "html[data-turbo='false']"
  end

  test "invitation pages keep display typography for guests and in the theme iframe" do
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)
    get admin_theme_section_path(section: "save_the_date")

    {
      public_save_the_date_path => /Save the Date/i,
      public_rsvp_lookup_path => /RSVP/i
    }.each do |path, eyebrow|
      get path, params: { skip_video: "1" }
      assert_response :success, "expected guest markup on #{path}"
      assert_select "h1.invitation-title", text: @wedding.title
      assert_select "p.invitation-eyebrow", text: eyebrow
      assert_select "h1.invitation-title[data-site-editor-target='hotspot']", count: 0

      get_iframe path, params: { skip_video: "1" }
      assert_response :success, "expected editor markup on #{path}"
      assert_select "h1.invitation-title[data-site-editor-target='hotspot']", text: @wedding.title
      assert_select "meta[name='turbo'][content='false']"
    end
  end

  test "home hero typography survives outside the theme iframe" do
    get root_path

    assert_response :success
    assert_select "h1.wedding-hero-title", minimum: 1
    assert_select "h1.wedding-hero-title[data-site-editor-target='hotspot']", count: 0
  end

  test "site editor stays active across iframe preview navigations" do
    @wedding.update!(
      wedding_party: @wedding.wedding_party.merge(
        "bridesmaids" => [{ "name" => "Nora", "role" => "Maid of Honour", "relation" => "Sister" }]
      )
    )
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)
    get admin_theme_section_path(section: "home")

    get_iframe root_path
    assert_response :success
    assert_select "[data-controller='site-editor']"
    assert_select "meta[name='turbo'][content='false']"
    assert_select "[data-site-editor-target='hotspot']"

    get_iframe public_wedding_party_path
    assert_response :success
    assert_select "[data-controller='site-editor']"
    assert_select "meta[name='turbo'][content='false']"
    assert_select "[data-site-editor-target='hotspot']"
    # Entrance animation class + observer target must share a node, otherwise
    # editor mode leaves party members stuck at opacity: 0.
    assert_select ".animate-on-scroll[data-scroll-animate-target='item']", minimum: 1
    assert_select ".animate-on-scroll[data-site-editor-target='hotspot']", count: 0
  end

  test "site editor hotspots appear after opening Theme" do
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)
    get admin_theme_section_path(section: "home")

    get_iframe root_path

    assert_response :success
    assert_select "[data-controller='site-editor']"
    assert_select "[data-site-editor-target='hotspot'][data-kind='text']"
    assert_select "[data-site-editor-target='hotspot'][data-kind='essentials']"
    assert_select "[data-site-editor-target='hotspot'][data-kind='slot']"
  end

  test "button label hotspots keep button chrome without nesting anchors" do
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)
    get admin_theme_section_path(section: "home")

    get_iframe root_path

    assert_response :success
    assert_select "[data-site-editor-target='hotspot'][data-surface='button'][data-field='rsvp_copy.button_text']",
                  text: @wedding.rsvp["button_text"]
    assert_select "[data-site-editor-target='hotspot'][data-field='rsvp_copy.button_text'] a", count: 0
    assert_select "[data-site-editor-target='hotspot'][data-field='rsvp_copy.button_text'].btn-wedding-primary"

    get_iframe public_save_the_date_path

    assert_response :success
    assert_select "[data-site-editor-target='hotspot'][data-surface='button'][data-field='save_the_date_copy.calendar_button_text']"
    assert_select "[data-site-editor-target='hotspot'][data-field='save_the_date_copy.calendar_button_text'] a", count: 0
    assert_select "[data-site-editor-target='hotspot'][data-surface='button'][data-field='save_the_date_copy.submit_button_text']"
    assert_select "[data-site-editor-target='hotspot'][data-field='save_the_date_copy.submit_button_text'] input", count: 0
    assert_select "[data-site-editor-target='hotspot'][data-field='save_the_date_copy.submit_button_text'] button", count: 0
  end

  test "guests still get real links and submit buttons for CTA labels" do
    get root_path

    assert_select "a.btn-wedding-primary[href=?]", public_rsvp_lookup_path,
                  text: @wedding.rsvp["button_text"]
    assert_select "[data-surface='button']", count: 0

    get public_save_the_date_path

    assert_select "a.btn-wedding-primary", minimum: 1
    assert_select "button.btn-wedding-primary[type='submit']", minimum: 1
    assert_select "[data-surface='button']", count: 0
  end

  test "editor mode annotates every guest page with the right hotspot kinds" do
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)
    get admin_theme_section_path(section: "home")

    {
      root_path => %w[text essentials slot panel],
      public_faq_path => %w[text panel],
      public_photos_path => %w[text],
      public_wedding_party_path => %w[text],
      public_save_the_date_path => %w[text essentials slot],
      public_rsvp_lookup_path => %w[essentials slot]
    }.each do |path, kinds|
      get_iframe path

      assert_response :success, "expected #{path} to render in editor mode"
      assert_select "[data-controller='site-editor']"
      assert_select "meta[name='turbo'][content='false']"
      kinds.each do |kind|
        assert_select "[data-site-editor-target='hotspot'][data-kind=?]", kind
      end
    end
  end

  test "editor mode shows empty photo slot placeholders" do
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)
    get admin_theme_section_path(section: "rsvp")

    get_iframe public_rsvp_lookup_path

    assert_response :success
    assert_select ".site-editor-slot--empty"
    assert_select ".site-editor-empty-label", minimum: 1
  end

  test "editorial and parallax themes expose editor hotspots too" do
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)
    get admin_theme_section_path(section: "home")

    %w[editorial parallax].each do |key|
      @wedding.update!(theme: { "key" => key })

      get_iframe root_path

      assert_response :success
      assert_select "[data-site-editor-target='hotspot'][data-kind='text']"
      assert_select "[data-site-editor-target='hotspot'][data-kind='essentials']"
      assert_select "[data-site-editor-target='hotspot'][data-kind='slot']"
    end
  end

  test "a visitor never sees an admin's preview draft" do
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)
    post admin_theme_preview_path, params: { theme: { key: "parallax" } }

    get root_path
    assert_select "html[data-theme='#{SiteThemes::DEFAULT_KEY}']",
                  1,
                  "a top-level public visit must use the saved theme, not the draft"
    assert_select ".theme-preview-banner", count: 0

    get_iframe root_path
    assert_select "html[data-theme='parallax']", 1, "the Theme iframe should still see the draft"
    assert_select ".theme-preview-banner"

    delete admin_logout_path

    get root_path
    assert_select "html[data-theme='#{SiteThemes::DEFAULT_KEY}']"
    assert_select ".theme-preview-banner", count: 0
  end

  test "a preview reaches pages the schedule would hide" do
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)
    get admin_theme_section_path(section: "home")
    WeddingMetadata.create!(wedding_id: @wedding.id, key: "save_the_date_mode", value: "true")

    get_iframe public_faq_path
    assert_response :success, "save the date mode should not collapse the Theme editor preview"
    assert_select ".theme-preview-banner", text: /Save the Date mode/
  end

  test "save the date mode still collapses the site for guests" do
    WeddingMetadata.create!(wedding_id: @wedding.id, key: "save_the_date_mode", value: "true")

    get public_faq_path

    assert_redirected_to public_save_the_date_path
  end

  test "save the date mode still collapses top-level visits for a signed-in admin" do
    admin = create_admin_for(@wedding)
    sign_in_admin(admin)
    get admin_theme_section_path(section: "home")
    WeddingMetadata.create!(wedding_id: @wedding.id, key: "save_the_date_mode", value: "true")

    get public_faq_path

    assert_redirected_to public_save_the_date_path
  end
end

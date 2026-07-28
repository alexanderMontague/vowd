require "test_helper"

class Admin::ThemesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @wedding = create_wedding
    @admin = create_admin_for(@wedding)
    sign_in_admin(@admin)
    DisposableCamera::StorageClient.reset_adapter!
  end

  teardown do
    DisposableCamera::StorageClient.reset_adapter!
  end

  test "theme root redirects to home section" do
    get admin_theme_path

    assert_redirected_to admin_theme_section_path(section: "home")
  end

  test "the look section offers every shipped theme, font pairing and toggleable page" do
    get admin_theme_section_path(section: "look")

    assert_response :success

    SiteThemes.keys.each do |key|
      assert_select "input[name='theme[key]'][value=?]", key
    end

    SiteThemes::COLOR_KEYS.each do |role|
      assert_select "input[name=?]", "theme[colors][#{role}]"
    end

    SitePages.toggleable_keys.each do |key|
      assert_select "input[name=?]", "theme[pages][#{key}]"
    end

    assert_select "select[name='theme[font]'] option", count: SiteFonts.keys.size
  end

  test "every section renders the full-bleed visual editor shell" do
    ThemeSections.keys.each do |key|
      get admin_theme_section_path(section: key)

      assert_response :success, "expected #{key} to render"
      assert_select ".theme-editor--visual"
      assert_select ".theme-preview--canvas"
      assert_select ".theme-editor-drawer"
      assert_select "iframe.theme-preview__frame"
      assert_select ".theme-editor-slot-pickers [data-asset-picker-target='picker']"
      assert_select "[data-theme-editor-target='panel'][data-panel='look']"
      assert_select "[data-theme-editor-target='panel'][data-panel='home_settings']"
    end
  end

  test "content autosave works even when the chrome section is look" do
    patch admin_theme_section_path(section: "look"),
          params: { wedding: { hero: { tagline: "From look URL" } } },
          as: :json

    assert_response :success
    assert_equal true, response.parsed_body["ok"]
    assert_equal "From look URL", @wedding.reload.hero["tagline"]
  end

  test "look save without a theme returns json instead of missing template" do
    patch admin_theme_section_path(section: "look"),
          params: {},
          as: :json

    assert_response :unprocessable_content
    assert_equal false, response.parsed_body["ok"]
  end

  test "page chrome uses site navigation only — settings live in the preview bar" do
    get admin_theme_section_path(section: "home")

    assert_response :success
    assert_select "[data-action='theme-editor#openSettings']", text: /Settings/
    assert_select "[data-action='theme-editor#toggleSkipVideo']"
    assert_select "[data-theme-editor-target='skipVideoControl'][hidden]"
    assert_select "[data-action='theme-editor#showPageTab']"
    assert_select "[data-action='theme-editor#showThemeTab']", text: /Theme/
    assert_select "[data-action='theme-editor#openLook']", count: 0
    assert_select "[data-action='theme-editor#openCurrentSettings']", count: 0
    assert_select "[data-action='theme-editor#openSection']", count: 0
    assert_select "[data-theme-editor-section-urls-value]"
    assert_select "[data-theme-editor-target='frameLoading']"
    assert_includes response.body, "Use the site menu in the preview"
    assert_select "button[form='theme_look_form']", text: "Save theme"
    assert_select "form.theme-editor-form[data-action*='autosaveForm']"
  end

  test "skip intro toggle is visible on invitation page sections" do
    %w[save_the_date rsvp].each do |section|
      get admin_theme_section_path(section: section)

      assert_response :success
      assert_select "[data-theme-editor-target='skipVideoControl']:not([hidden])"
      assert_select "[data-action='theme-editor#toggleSkipVideo']"
    end
  end

  test "theme editor exposes page path maps so iframe navigation can sync the admin URL" do
    get admin_theme_section_path(section: "home")

    assert_response :success
    assert_select "[data-theme-editor-pages-value]"
    assert_select "[data-theme-editor-section-urls-value]"

    pages = JSON.parse(css_select("[data-theme-editor-pages-value]").first["data-theme-editor-pages-value"])
    urls = JSON.parse(css_select("[data-theme-editor-section-urls-value]").first["data-theme-editor-section-urls-value"])

    assert_equal "home", pages[root_path]
    assert_equal "save_the_date", pages[public_save_the_date_path]
    assert_equal "rsvp", pages[public_rsvp_lookup_path]
    assert_equal admin_theme_section_path(section: "save_the_date"), urls["save_the_date"]
    assert_equal admin_theme_section_path(section: "rsvp"), urls["rsvp"]
    assert_equal admin_theme_section_path(section: "wedding_party"), urls["wedding_party"]
  end

  test "content save url never points at look" do
    get admin_theme_section_path(section: "look")

    assert_response :success
    assert_select "[data-theme-editor-save-url-value='#{admin_theme_section_path(section: "home")}']"
  end

  test "content autosave returns json without redirect" do
    patch admin_theme_section_path(section: "home"),
          params: { wedding: { hero: { tagline: "Autosaved" } } },
          as: :json

    assert_response :success
    assert_equal true, response.parsed_body["ok"]
    assert_equal "Autosaved", @wedding.reload.hero["tagline"]
  end

  test "html content save still redirects with a flash notice" do
    patch admin_theme_section_path(section: "home"),
          params: { wedding: { hero: { tagline: "Redirected" } } }

    assert_redirected_to admin_theme_section_path(section: "home")
    follow_redirect!
    assert_equal "Redirected", @wedding.reload.hero["tagline"]
  end

  test "partial faq title autosave keeps existing questions" do
    @wedding.update!(faq: {
      "title" => "FAQ",
      "subtitle" => "Ask",
      "questions" => [{ "question" => "When?", "answer" => "Soon" }]
    })

    patch admin_theme_section_path(section: "faq"),
          params: { wedding: { faq: { title: "Questions" } } },
          as: :json

    assert_response :success
    faq = @wedding.reload.faq
    assert_equal "Questions", faq["title"]
    assert_equal "Ask", faq["subtitle"]
    assert_equal "When?", faq["questions"].first["question"]
  end

  test "partial story title autosave keeps paragraphs and enabled flag" do
    @wedding.update!(story: {
      "enabled" => true,
      "title" => "Our Story",
      "paragraphs" => ["Once upon a time"],
      "closing" => "The end"
    })

    patch admin_theme_section_path(section: "home"),
          params: { wedding: { story: { title: "How We Met" } } },
          as: :json

    assert_response :success
    story = @wedding.reload.story
    assert_equal "How We Met", story["title"]
    assert_equal true, story["enabled"]
    assert_equal ["Once upon a time"], story["paragraphs"]
    assert_equal "The end", story["closing"]
  end

  test "partial wedding party title autosave keeps members" do
    @wedding.update!(wedding_party: {
      "title" => "Wedding Party",
      "subtitle" => "Our people",
      "bridesmaids_title" => "Bridesmaids",
      "groomsmen_title" => "Groomsmen",
      "bridesmaids" => [{ "name" => "Nora", "role" => "Maid of Honour", "relation" => "Sister" }],
      "groomsmen" => [{ "name" => "Sam", "role" => "Best Man", "relation" => "Brother" }]
    })

    patch admin_theme_section_path(section: "wedding_party"),
          params: { wedding: { wedding_party: { title: "The Crew" } } },
          as: :json

    assert_response :success
    party = @wedding.reload.wedding_party
    assert_equal "The Crew", party["title"]
    assert_equal "Our people", party["subtitle"]
    assert_equal "Nora", party["bridesmaids"].first["name"]
    assert_equal "Sam", party["groomsmen"].first["name"]
  end

  test "partial rsvp copy autosave keeps sibling fields" do
    @wedding.update!(rsvp_copy: {
      "title" => "Join Us",
      "description" => "Please RSVP",
      "button_text" => "RSVP Now",
      "lookup_hint" => "Use your invite link"
    })

    patch admin_theme_section_path(section: "rsvp"),
          params: { wedding: { rsvp_copy: { title: "Will you join?" } } },
          as: :json

    assert_response :success
    copy = @wedding.reload.rsvp_copy
    assert_equal "Will you join?", copy["title"]
    assert_equal "Please RSVP", copy["description"]
    assert_equal "RSVP Now", copy["button_text"]
  end

  test "partial save the date copy autosave keeps sibling fields" do
    @wedding.update!(save_the_date_copy: {
      "eyebrow" => "Save the Date",
      "announcement" => "We are engaged",
      "formal_note" => "Invite later",
      "signup_eyebrow" => "Stay close",
      "signup_prompt" => "Leave your email",
      "calendar_button_text" => "Add to Calendar",
      "submit_button_text" => "Share"
    })

    patch admin_theme_section_path(section: "save_the_date"),
          params: { wedding: { save_the_date_copy: { eyebrow: "Mark it" } } },
          as: :json

    assert_response :success
    copy = @wedding.reload.save_the_date
    assert_equal "Mark it", copy["eyebrow"]
    assert_equal "We are engaged", copy["announcement"]
    assert_equal "Share", copy["submit_button_text"]
  end

  test "placement autosave json merges without wiping other slots" do
    hero, portrait = Array.new(2) { create_asset }
    @wedding.update!(placements: { "homepage_hero" => [hero.id] })

    patch admin_theme_section_path(section: "save_the_date"),
          params: { wedding: { placements: { "save_the_date_portrait" => ["", portrait.id] } } },
          as: :json

    assert_response :success
    @wedding.reload
    assert_equal [hero.id], @wedding.placements["homepage_hero"]
    assert_equal [portrait.id], @wedding.placements["save_the_date_portrait"]
  end

  test "opening the theme editor activates site editor session" do
    get admin_theme_section_path(section: "home")

    assert_equal @wedding.id, session[SiteEditor::SESSION_KEY]
  end

  test "leaving theme admin clears the site editor session" do
    get admin_theme_section_path(section: "home")
    assert_equal @wedding.id, session[SiteEditor::SESSION_KEY]

    get admin_root_path

    assert_nil session[SiteEditor::SESSION_KEY]
  end

  test "wedding essentials clears the site editor session" do
    get admin_theme_section_path(section: "home")
    assert_equal @wedding.id, session[SiteEditor::SESSION_KEY]

    get admin_website_section_path(section: "essentials")

    assert_nil session[SiteEditor::SESSION_KEY]
  end

  test "photo library uploads while editing keep the site editor session" do
    get admin_theme_section_path(section: "photos")
    assert_equal @wedding.id, session[SiteEditor::SESSION_KEY]

    post admin_website_assets_path,
         params: { purpose: "photos", file: fixture_file_upload("test_image.jpg", "image/jpeg") },
         headers: { "Accept" => "application/json" }

    assert_response :created
    assert_equal @wedding.id, session[SiteEditor::SESSION_KEY]
  end

  test "saving look persists the theme and stays on the section" do
    patch admin_theme_section_path(section: "look"), params: {
      theme: {
        key: "parallax",
        font: "modern",
        colors: { "primary" => "#abc", "accent" => "not a colour" },
        pages: { "faq" => "0", "gallery" => "1" }
      }
    }

    assert_redirected_to admin_theme_section_path(section: "look")

    theme = @wedding.reload.site_theme

    assert_equal "parallax", theme.key
    assert_equal "modern", theme.font.key
    assert_equal "#AABBCC", theme.color("primary")
    assert_equal SiteThemes.find("parallax").default_colors["accent"], theme.color("accent"),
                 "an unparseable colour should fall back rather than be stored"
    assert_not theme.page_enabled?("faq")
    assert theme.page_enabled?("gallery")
  end

  test "saving photos section persists gallery sections and stays on the section" do
    assets = Array.new(2) { create_asset }

    patch admin_theme_section_path(section: "photos"), params: {
      wedding: {
        photos_page: {
          title: "Our Photos",
          subtitle: "Moments",
          sections: {
            "0" => { title: "Engagement", asset_ids: ["", assets[0].id, assets[1].id] }
          }
        },
        placements: {
          "invitation_envelope" => [""]
        }
      }
    }

    assert_redirected_to admin_theme_section_path(section: "photos")
    @wedding.reload
    assert_equal "Our Photos", @wedding.photos_page["title"]
    assert_equal [assets[0].id, assets[1].id], @wedding.photos_page["sections"].first["asset_ids"]
  end

  test "photos section does not nest a bulk-delete form inside the save form" do
    get admin_theme_section_path(section: "photos")

    assert_response :success
    assert_select "form.theme-editor-form"
    assert_select "form#photo_library_bulk_delete"
    assert_select "form.theme-editor-form form", count: 0
  end

  test "content sections expose cross-page photo usage for the picker" do
    shared = create_asset
    @wedding.update!(
      placements: {
        "homepage_hero" => [shared.id],
        "rsvp_floating" => [shared.id]
      }
    )

    get admin_theme_section_path(section: "rsvp")

    assert_response :success
    usage = AssetUsageIndex.call(@wedding.reload)
    assert_includes response.body, "data-asset-picker-usage-value"
    assert_includes usage[shared.id], "Homepage · Hero image"
    assert_includes usage[shared.id], "RSVP · Floating photos"
  end

  test "saving home content persists hero and stays on the section" do
    asset = create_asset

    patch admin_theme_section_path(section: "home"), params: {
      wedding: {
        hero: { tagline: "Join Us" },
        placements: { "homepage_hero" => ["", asset.id] },
        story: { enabled: "1", title: "Our Story", paragraphs_text: "Once upon a time", closing: "" }
      }
    }

    assert_redirected_to admin_theme_section_path(section: "home")
    @wedding.reload
    assert_equal "Join Us", @wedding.hero["tagline"]
    assert_equal [asset.id], @wedding.placements["homepage_hero"]
    assert_equal "Our Story", @wedding.story["title"]
  end

  test "saving save the date copy persists custom wording" do
    patch admin_theme_section_path(section: "save_the_date"), params: {
      wedding: {
        save_the_date_copy: {
          eyebrow: "Mark Your Calendars",
          announcement: "We are getting married!",
          formal_note: "Invite to follow",
          signup_eyebrow: "Stay close",
          signup_prompt: "Drop your email.",
          calendar_button_text: "Add day",
          submit_button_text: "Send it"
        }
      }
    }

    assert_redirected_to admin_theme_section_path(section: "save_the_date")
    copy = @wedding.reload.save_the_date
    assert_equal "Mark Your Calendars", copy["eyebrow"]
    assert_equal "We are getting married!", copy["announcement"]
    assert_equal "Send it", copy["submit_button_text"]
  end

  test "placements from one page merge without wiping another page" do
    hero, portrait = Array.new(2) { create_asset }
    @wedding.update!(placements: { "homepage_hero" => [hero.id] })

    patch admin_theme_section_path(section: "save_the_date"), params: {
      wedding: {
        save_the_date_copy: { eyebrow: "Save the Date" },
        placements: { "save_the_date_portrait" => ["", portrait.id] }
      }
    }

    @wedding.reload
    assert_equal [hero.id], @wedding.placements["homepage_hero"]
    assert_equal [portrait.id], @wedding.placements["save_the_date_portrait"]
  end

  test "an unknown theme key is rejected and changes nothing" do
    original = @wedding.site_theme

    patch admin_theme_section_path(section: "look"), params: { theme: { key: "art-deco-from-2019" } }

    assert_response :unprocessable_content
    assert_equal original, @wedding.reload.site_theme
  end

  test "a submission with no theme at all is rejected rather than crashing" do
    patch admin_theme_section_path(section: "look")

    assert_response :unprocessable_content
  end

  test "saving clears the preview draft so the editor stops showing unsaved changes" do
    post admin_theme_preview_path, params: { theme: { key: "editorial" } }
    assert_equal "editorial", session_theme_key

    patch admin_theme_section_path(section: "look"), params: { theme: { key: "parallax" } }

    assert_nil session[ThemePreviewing::SESSION_KEY]
  end

  test "previewing stores a draft without touching the saved theme" do
    post admin_theme_preview_path, params: {
      theme: { key: "editorial", colors: { "primary" => "#123456" } }
    }

    assert_response :no_content
    assert_equal "editorial", session_theme_key
    assert_equal SiteThemes::DEFAULT_KEY, @wedding.reload.site_theme.key
  end

  test "previewing ignores a leaked Save form method override" do
    post admin_theme_preview_path, params: {
      _method: "patch",
      theme: { key: "parallax" }
    }

    assert_response :no_content
    assert_equal "parallax", session_theme_key
  end

  test "a preview naming an unknown theme is refused" do
    post admin_theme_preview_path, params: { theme: { key: "nope" } }

    assert_response :unprocessable_content
    assert_nil session[ThemePreviewing::SESSION_KEY]
  end

  test "discarding a preview drops the draft" do
    post admin_theme_preview_path, params: { theme: { key: "editorial" } }

    delete admin_theme_preview_path

    assert_redirected_to admin_theme_section_path(section: "home")
    assert_nil session[ThemePreviewing::SESSION_KEY]
  end

  test "the editor reopens on the unsaved draft rather than the saved theme" do
    post admin_theme_preview_path, params: { theme: { key: "editorial" } }

    get admin_theme_section_path(section: "look")

    assert_response :success
    assert_select "input[name='theme[key]'][value='editorial'][checked]"
  end

  test "signing out is enough to stop a draft being honoured" do
    post admin_theme_preview_path, params: { theme: { key: "editorial" } }
    delete admin_logout_path

    get root_path

    assert_select "html[data-theme=?]", SiteThemes::DEFAULT_KEY
  end

  test "a signed out admin cannot preview" do
    delete admin_logout_path

    post admin_theme_preview_path, params: { theme: { key: "editorial" } }

    assert_redirected_to admin_login_path
  end

  private

  def session_theme_key
    session.dig(ThemePreviewing::SESSION_KEY, "theme", "key")
  end

  def create_asset
    @wedding.wedding_assets.create!(
      object_key: "#{Rails.env}/#{@wedding.id}/site/photos/#{SecureRandom.hex(6)}.webp",
      content_type: "image/webp",
      byte_size: 2048
    )
  end
end

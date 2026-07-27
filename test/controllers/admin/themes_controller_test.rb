require "test_helper"

class Admin::ThemesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @wedding = create_wedding
    @admin = create_admin_for(@wedding)
    sign_in_admin(@admin)
  end

  test "theme root redirects to look section" do
    get admin_theme_path

    assert_redirected_to admin_theme_section_path(section: "look")
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

  test "page sections render content controls beside the preview" do
    get admin_theme_section_path(section: "home")

    assert_response :success
    assert_includes response.body, "Hero tagline"
    assert_includes response.body, "theme-preview"
    assert_includes response.body, "Save page"
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

    assert_redirected_to admin_theme_section_path(section: "look")
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

  test "an admin cannot reach another wedding's theme editor" do
    other = create_wedding
    create_admin_for(other)
    host_wedding!(other)

    get admin_theme_section_path(section: "look")

    assert_redirected_to admin_login_path
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

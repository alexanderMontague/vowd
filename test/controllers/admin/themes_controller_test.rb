require "test_helper"

class Admin::ThemesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @wedding = create_wedding
    @admin = create_admin_for(@wedding)
    sign_in_admin(@admin)
  end

  test "the editor offers every shipped theme, font pairing and toggleable page" do
    get admin_theme_path

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

  test "saving persists the whole theme and normalises what it stores" do
    patch admin_theme_path, params: {
      theme: {
        key: "parallax",
        font: "modern",
        colors: { "primary" => "#abc", "accent" => "not a colour" },
        pages: { "faq" => "0", "gallery" => "1" }
      }
    }

    assert_redirected_to admin_theme_path

    theme = @wedding.reload.site_theme

    assert_equal "parallax", theme.key
    assert_equal "modern", theme.font.key
    assert_equal "#AABBCC", theme.color("primary")
    assert_equal SiteThemes.find("parallax").default_colors["accent"], theme.color("accent"),
                 "an unparseable colour should fall back rather than be stored"
    assert_not theme.page_enabled?("faq")
    assert theme.page_enabled?("gallery")
  end

  test "an unknown theme key is rejected and changes nothing" do
    original = @wedding.site_theme

    patch admin_theme_path, params: { theme: { key: "art-deco-from-2019" } }

    assert_response :unprocessable_content
    assert_equal original, @wedding.reload.site_theme
  end

  test "a submission with no theme at all is rejected rather than crashing" do
    patch admin_theme_path

    assert_response :unprocessable_content
  end

  test "saving clears the preview draft so the editor stops showing unsaved changes" do
    post admin_theme_preview_path, params: { theme: { key: "editorial" } }
    assert_equal "editorial", session_theme_key

    patch admin_theme_path, params: { theme: { key: "parallax" } }

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

  # The editor posts the Save form's fields to the preview endpoint. If `_method`
  # leaks through, Rails rewrites the request to PATCH and the route 404s.
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

    assert_redirected_to admin_theme_path
    assert_nil session[ThemePreviewing::SESSION_KEY]
  end

  test "the editor reopens on the unsaved draft rather than the saved theme" do
    post admin_theme_preview_path, params: { theme: { key: "editorial" } }

    get admin_theme_path

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

    get admin_theme_path

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
end

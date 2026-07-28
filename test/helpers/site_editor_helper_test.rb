require "test_helper"

class SiteEditorHelperTest < ActionView::TestCase
  tests SiteEditorHelper

  setup do
    @site_editor_active = false
  end

  test "editor_text always wraps guests in the public tag and class" do
    @site_editor_active = false

    html = editor_text("hero.tagline", tag: :p, css_class: "wedding-hero-subtitle") { "Together forever" }

    assert_includes html, '<p class="wedding-hero-subtitle">'
    assert_includes html, "Together forever"
    assert_not_includes html, "data-site-editor-target"
    assert_not_includes html, "data-kind"
  end

  test "editor_essentials always wraps guests in the public tag and class" do
    @site_editor_active = false

    html = editor_essentials(tag: :h1, css_class: "invitation-title") { "Britt and Alex" }

    assert_includes html, '<h1 class="invitation-title">'
    assert_includes html, "Britt and Alex"
    assert_not_includes html, "data-site-editor-target"
    assert_not_includes html, 'data-kind="essentials"'
  end

  test "editor_text adds hotspot attributes only in the theme iframe" do
    @site_editor_active = true

    html = editor_text("hero.tagline", tag: :p, css_class: "wedding-hero-subtitle", multiline: true) { "Together forever" }

    assert_includes html, '<p class="wedding-hero-subtitle"'
    assert_includes html, 'data-site-editor-target="hotspot"'
    assert_includes html, 'data-kind="text"'
    assert_includes html, 'data-field="hero.tagline"'
    assert_includes html, 'data-multiline="true"'
  end

  test "editor_essentials adds hotspot attributes only in the theme iframe" do
    @site_editor_active = true

    html = editor_essentials(tag: :h1, css_class: "invitation-title") { "Britt and Alex" }

    assert_includes html, '<h1 class="invitation-title"'
    assert_includes html, 'data-site-editor-target="hotspot"'
    assert_includes html, 'data-kind="essentials"'
    assert_includes html, 'href="/admin/website/essentials"'
  end

  test "editor_slot and editor_panel stay inert for guests" do
    @site_editor_active = false

    slot_html = editor_slot("hero") { "<img src='/x.jpg'>".html_safe }
    panel_html = editor_panel("faq") { "<p>Question</p>".html_safe }

    assert_equal "<img src='/x.jpg'>", slot_html
    assert_equal "<p>Question</p>", panel_html
  end

  private

  def site_editor_active?
    @site_editor_active
  end
end

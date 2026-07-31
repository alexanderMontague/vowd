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
    wrapped_html = editor_slot("hero", css_class: "wedding-hero-slot") { "<img src='/x.jpg'>".html_safe }
    panel_html = editor_panel("faq") { "<p>Question</p>".html_safe }

    assert_equal "<img src='/x.jpg'>", slot_html
    assert_equal "<div class=\"wedding-hero-slot\"><img src='/x.jpg'></div>", wrapped_html
    assert_equal "<p>Question</p>", panel_html
    assert_not_includes wrapped_html, "data-site-editor-target"
  end

  test "editor_text strips leading and trailing whitespace from ERB indentation" do
    @site_editor_active = false

    html = editor_text("hero.tagline", tag: :p, css_class: "wedding-hero-subtitle") do
      "

        Together forever

      "
    end

    assert_includes html, ">Together forever<"
    assert_not_includes html, ">Together forever\n"
  end

  test "editor_link renders a real anchor for guests" do
    @site_editor_active = false

    html = editor_link("rsvp_copy.button_text", href: "/rsvp", css_class: "btn-wedding-primary") { "RSVP Now" }

    assert_includes html, '<a class="btn-wedding-primary" href="/rsvp">'
    assert_includes html, "RSVP Now"
    assert_not_includes html, "data-site-editor-target"
    assert_not_includes html, "<span"
  end

  test "editor_link becomes a button-surface hotspot in the theme iframe" do
    @site_editor_active = true

    html = editor_link("rsvp_copy.button_text", href: "/rsvp", css_class: "btn-wedding-primary") { "RSVP Now" }

    assert_includes html, 'class="btn-wedding-primary"'
    assert_includes html, 'data-site-editor-target="hotspot"'
    assert_includes html, 'data-kind="text"'
    assert_includes html, 'data-field="rsvp_copy.button_text"'
    assert_includes html, 'data-surface="button"'
    assert_includes html, "RSVP Now"
    assert_not_includes html, "<a "
    assert_not_includes html, 'href="/rsvp"'
  end

  test "editor_button renders a submit control for guests and a hotspot while editing" do
    @site_editor_active = false
    guest = editor_button("save_the_date_copy.submit_button_text", css_class: "btn-wedding-primary") { "Share My Details" }
    assert_includes guest, '<button name="button" type="submit" class="btn-wedding-primary">'
    assert_includes guest, "Share My Details"

    @site_editor_active = true
    editing = editor_button("save_the_date_copy.submit_button_text", css_class: "btn-wedding-primary") { "Share My Details" }
    assert_includes editing, 'data-surface="button"'
    assert_includes editing, 'data-field="save_the_date_copy.submit_button_text"'
    assert_not_includes editing, "<button"
  end

  private

  def site_editor_active?
    @site_editor_active
  end
end

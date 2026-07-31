# Attribute helpers for Shopify-style click-to-edit hotspots on the guest site.
# Tag + css_class are always rendered — they ARE the public markup. Editor data
# attributes are only added inside the Theme iframe.
module SiteEditorHelper
  def editor_text(field, tag: :span, css_class: nil, multiline: false, &block)
    content = strip_editor_text(capture(&block))
    options = { class: css_class }
    if site_editor_active?
      options[:data] = {
        site_editor_target: "hotspot",
        kind: "text",
        field: field,
        multiline: multiline.presence
      }.compact
    end

    content_tag(tag, content, options)
  end

  # Button / CTA labels. In the theme iframe the control becomes a styled span so
  # contenteditable can edit the label without destroying link/button chrome.
  def editor_link(field, href:, css_class: nil, **html_options, &block)
    content = strip_editor_text(capture(&block))
    if site_editor_active?
      content_tag(
        :span,
        content,
        class: css_class,
        data: {
          site_editor_target: "hotspot",
          kind: "text",
          field: field,
          surface: "button"
        }
      )
    else
      link_to(content, href, html_options.merge(class: css_class))
    end
  end

  def editor_button(field, type: "submit", css_class: nil, &block)
    content = strip_editor_text(capture(&block))
    if site_editor_active?
      content_tag(
        :span,
        content,
        class: css_class,
        data: {
          site_editor_target: "hotspot",
          kind: "text",
          field: field,
          surface: "button"
        }
      )
    else
      button_tag(content, type: type, class: css_class)
    end
  end

  def editor_essentials(tag: :span, css_class: nil, &block)
    content = strip_editor_text(capture(&block))
    options = { class: css_class }
    if site_editor_active?
      options[:data] = {
        site_editor_target: "hotspot",
        kind: "essentials",
        href: admin_website_section_path(section: "essentials")
      }
    end

    content_tag(tag, content, options)
  end

  def editor_slot(slot_key, tag: :div, css_class: nil, &block)
    content = block_given? ? capture(&block) : nil

    unless site_editor_active?
      return content if css_class.blank?

      return content_tag(tag, content, class: css_class)
    end

    slot = SiteSlots.find(slot_key)
    empty = content.blank?

    content_tag(
      tag,
      empty ? editor_empty_slot_label(slot) : content,
      class: [css_class, ("site-editor-slot--empty" if empty)].compact.join(" "),
      data: {
        site_editor_target: "hotspot",
        kind: "slot",
        slot: slot_key,
        max: slot&.max || 1
      }
    )
  end

  def editor_panel(panel, tag: :div, css_class: nil, &block)
    content = capture(&block)
    return content unless site_editor_active?

    content_tag(
      tag,
      content,
      class: css_class,
      data: {
        site_editor_target: "hotspot",
        kind: "panel",
        panel: panel
      }
    )
  end

  def editor_empty_slot_label(slot)
    label = slot&.label || "Photo"
    content_tag(:span, "Add #{label.downcase}", class: "site-editor-empty-label")
  end

  private

  # ERB indentation inside editor_* blocks becomes leading/trailing text nodes;
  # strip those so click-to-edit never starts with whitespace.
  def strip_editor_text(content)
    return content if content.blank?

    stripped = content.to_s.strip
    content.html_safe? ? stripped.html_safe : stripped
  end
end

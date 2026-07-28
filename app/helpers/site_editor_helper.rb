# Attribute helpers for Shopify-style click-to-edit hotspots on the guest site.
# All helpers no-op for real guests — attributes are only emitted in editor mode.
module SiteEditorHelper
  def editor_text(field, tag: :span, css_class: nil, multiline: false, &block)
    content = capture(&block)
    return content unless site_editor_active?

    content_tag(
      tag,
      content,
      class: css_class,
      data: {
        site_editor_target: "hotspot",
        kind: "text",
        field: field,
        multiline: multiline.presence
      }.compact
    )
  end

  def editor_essentials(tag: :span, css_class: nil, &block)
    content = capture(&block)
    return content unless site_editor_active?

    content_tag(
      tag,
      content,
      class: css_class,
      data: {
        site_editor_target: "hotspot",
        kind: "essentials",
        href: admin_website_section_path(section: "essentials")
      }
    )
  end

  def editor_slot(slot_key, tag: :div, css_class: nil, &block)
    content = block_given? ? capture(&block) : nil
    return content unless site_editor_active?

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
end

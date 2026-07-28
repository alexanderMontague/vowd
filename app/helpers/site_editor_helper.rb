# Attribute helpers for Shopify-style click-to-edit hotspots on the guest site.
# Tag + css_class are always rendered — they ARE the public markup. Editor data
# attributes are only added inside the Theme iframe.
module SiteEditorHelper
  def editor_text(field, tag: :span, css_class: nil, multiline: false, &block)
    content = capture(&block)
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

  def editor_essentials(tag: :span, css_class: nil, &block)
    content = capture(&block)
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

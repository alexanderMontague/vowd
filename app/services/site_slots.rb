# Named positions on the public site that a wedding can fill with photos from its
# library. Slots are the seam between stored placements and the decor component
# that renders them: `treatment` names the composition, so a future theme can
# reinterpret a slot without the stored data changing.
class SiteSlots
  Slot = Data.define(:key, :label, :description, :page, :max, :treatment)

  DEFINITIONS = [
    Slot.new(
      key: "invitation_envelope",
      label: "Envelope open video",
      description: "The reveal animation guests see before the save the date and RSVP pages. The first frame becomes the poster.",
      page: :invitation,
      max: 1,
      treatment: :envelope_video
    ),
    Slot.new(
      key: "save_the_date_portrait",
      label: "Framed portrait",
      description: "A single photo set inside the lace oval frame, below the heading.",
      page: :save_the_date,
      max: 1,
      treatment: :oval_frame
    ),
    Slot.new(
      key: "save_the_date_floating",
      label: "Floating photos",
      description: "Up to three photos that drift alongside the invitation as guests scroll.",
      page: :save_the_date,
      max: 3,
      treatment: :floating
    ),
    Slot.new(
      key: "save_the_date_vase",
      label: "Photo with urn",
      description: "An arched photo with the flower urn resting against its corner.",
      page: :save_the_date,
      max: 1,
      treatment: :vase
    ),
    Slot.new(
      key: "rsvp_portrait",
      label: "Framed portrait",
      description: "A single photo set inside the lace oval frame, below the heading.",
      page: :rsvp,
      max: 1,
      treatment: :oval_frame
    ),
    Slot.new(
      key: "rsvp_floating",
      label: "Floating photos",
      description: "Up to three photos that drift alongside the form as guests scroll.",
      page: :rsvp,
      max: 3,
      treatment: :floating
    )
  ].freeze

  PAGE_LABELS = {
    invitation: "Invitation",
    save_the_date: "Save the Date",
    rsvp: "RSVP"
  }.freeze

  class << self
    def definitions
      DEFINITIONS
    end

    def find(key)
      DEFINITIONS.find { |slot| slot.key == key.to_s }
    end

    def keys
      DEFINITIONS.map(&:key)
    end

    def by_page
      DEFINITIONS.group_by(&:page)
    end

    def photo_slots
      DEFINITIONS.reject { |slot| slot.treatment == :envelope_video }
    end

    def photo_slots_by_page
      photo_slots.group_by(&:page)
    end

    def page_label(page)
      PAGE_LABELS.fetch(page.to_sym, page.to_s.titleize)
    end
  end
end

class WeddingFeatureFlags
  FlagDefinition = Data.define(
    :key,
    :label,
    :description,
    :category,
    :scheduled_state,
    :scheduled_label
  )

  # All known feature flags. The `scheduled_state` lambda computes the time/config-based
  # default when no metadata override exists. `scheduled_label` provides a human-readable
  # summary of what the schedule says and why.
  DEFINITIONS = [
    FlagDefinition.new(
      key: "save_the_date_mode",
      label: "Save the Date Mode",
      description: "Limit the public site to the save the date page only. All other guest pages redirect here.",
      category: :site,
      scheduled_state: ->(_wedding) { false },
      scheduled_label: ->(_wedding) { "Off by default" }
    ),
    FlagDefinition.new(
      key: "rsvp_visible",
      label: "RSVP Section Visible",
      description: "Show or hide the RSVP call-to-action section on the public wedding page.",
      category: :rsvp,
      scheduled_state: ->(wedding) {
        deadline = wedding.try(:rsvp_deadline)
        return true if deadline.blank?
        Date.current <= Date.parse(deadline.to_s)
      },
      scheduled_label: ->(wedding) {
        deadline = wedding.try(:rsvp_deadline)
        return "Always on (no deadline configured)" if deadline.blank?
        date = Date.parse(deadline.to_s)
        Date.current <= date ? "On until #{date.strftime('%b %-d, %Y')}" : "Off (deadline #{date.strftime('%b %-d, %Y')} passed)"
      }
    ),
    FlagDefinition.new(
      key: "dispo_accepting_photos",
      label: "Dispo Accepting Photos",
      description: "Allow guests to submit photos via the disposable camera.",
      category: :dispo,
      scheduled_state: ->(wedding) { !wedding.dispo_camera_locked? },
      scheduled_label: ->(wedding) {
        closes_at = wedding.dispo_camera_closes_at
        wedding.dispo_camera_locked? \
          ? "Off since #{closes_at.strftime('%b %-d, %Y %-I:%M %p')}" \
          : "On until #{closes_at.strftime('%b %-d, %Y %-I:%M %p')}"
      }
    ),
    FlagDefinition.new(
      key: "dispo_gallery_on_main_page",
      label: "Dispo Gallery on Photos Page",
      description: "Display the full disposable camera album as the last section on the public Photos page.",
      category: :dispo,
      scheduled_state: ->(_wedding) { false },
      scheduled_label: ->(_wedding) { "Off by default" }
    )
  ].freeze

  def self.definitions
    DEFINITIONS
  end

  def self.find(key)
    DEFINITIONS.find { |d| d.key == key.to_s }
  end

  def self.keys
    DEFINITIONS.map(&:key)
  end

  def self.by_category
    DEFINITIONS.group_by(&:category)
  end

  CATEGORY_LABELS = {
    site: "Site",
    rsvp: "RSVP",
    dispo: "Disposable Camera"
  }.freeze

  def self.category_label(category)
    CATEGORY_LABELS.fetch(category, category.to_s.titleize)
  end
end

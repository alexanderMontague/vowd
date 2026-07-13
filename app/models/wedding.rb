class Wedding < FrozenRecord::Base
  self.base_path = "db/"

  # Front-end display treatments for disposable camera photos. The original
  # upload is never modified; these only drive a layered filter rendered client-side.
  PHOTO_STYLES = %w[original retro bw].freeze
  DEFAULT_PHOTO_STYLE = "retro".freeze
  PHOTO_STYLE_METADATA_KEY = "dispo_photo_style".freeze

  class << self
    def current
      @current ||= first_or_error!
    end

    def reset_current!
      @current = nil
    end

    private

    def first_or_error!
      first || raise("No wedding found")
    end
  end

  def guests
    Guest.where(wedding_id: id)
  end

  def households
    Household.where(wedding_id: id)
  end

  def save_the_date_signups
    SaveTheDateSignup.where(wedding_id: id)
  end

  def events
    Event.where(wedding_id: id)
  end

  def metadata
    WeddingMetadata.where(wedding_id: id)
  end

  # Returns the effective boolean state of a feature flag, checking metadata overrides
  # first and falling back to the time/config-based scheduled state.
  def feature_flag(key)
    override = metadata.find_by(key: key.to_s)
    return ActiveModel::Type::Boolean.new.cast(override.value) unless override.nil?

    definition = WeddingFeatureFlags.find(key)
    return false unless definition

    definition.scheduled_state.call(self)
  end

  def save_the_date_mode?
    feature_flag("save_the_date_mode")
  end

  def rsvp_visible?
    feature_flag("rsvp_visible")
  end

  def dispo_accepting_photos?
    feature_flag("dispo_accepting_photos")
  end

  def dispo_gallery_on_main_page?
    feature_flag("dispo_gallery_on_main_page")
  end

  def dispo_gallery_visible?
    feature_flag("dispo_gallery_on_main_page")
  end

  # Admin-selected default display treatment for disposable camera photos.
  # Falls back to the configured default when unset or invalid.
  def dispo_photo_style
    value = metadata.find_by(key: PHOTO_STYLE_METADATA_KEY)&.value
    PHOTO_STYLES.include?(value) ? value : DEFAULT_PHOTO_STYLE
  end

  def date
    Date.parse(super)
  end

  # Returns the Time at which the disposable camera stops accepting photos.
  # otherwise derives the time from ceremony_time + wedding_duration_hours.
  def dispo_camera_closes_at
    tz = ActiveSupport::TimeZone[timezone] || Time.zone

    tz.parse("#{date} #{ceremony_time}") + wedding_duration_hours.to_i.hours
  rescue ArgumentError, TypeError
    tz.local(date.year, date.month, date.day) + 1.day
  end

  def dispo_camera_locked?
    Time.current >= dispo_camera_closes_at
  end

  def rsvp_stats
    total = guests.count
    accepted = guests.joins(:rsvp).where(rsvps: { status: "accepted" }).count
    declined = guests.joins(:rsvp).where(rsvps: { status: "declined" }).count
    pending = total - accepted - declined

    { total:, accepted:, declined:, pending: }
  end
end

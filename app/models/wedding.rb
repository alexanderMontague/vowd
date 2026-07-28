class Wedding < ApplicationRecord
  self.primary_key = "id"

  PHOTO_STYLES = %w[original retro bw].freeze
  DEFAULT_PHOTO_STYLE = "retro".freeze
  PHOTO_STYLE_METADATA_KEY = "dispo_photo_style".freeze

  SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  VENUE_LABEL_PARTS = %w[name city region].freeze

  # Where a stored image entry can carry its source: a library asset's key, an
  # uploaded object key, or a legacy absolute url.
  IMAGE_ENTRY_KEYS = %w[object_key url image_url].freeze

  DEFAULT_STORY = {
    "enabled" => false,
    "title" => "Our Story",
    "paragraphs" => [],
    "closing" => nil
  }.freeze

  DEFAULT_HERO = {
    "tagline" => "Request the Honour of Your Presence"
  }.freeze

  DEFAULT_GALLERY = {
    "enabled" => false,
    "title" => "Gallery",
    "images" => []
  }.freeze

  DEFAULT_RSVP_COPY = {
    "title" => "Join Us",
    "description" => "We would be delighted to have you celebrate with us. Please let us know if you can attend.",
    "button_text" => "RSVP Now",
    "lookup_hint" => "Or use the personalized link in your invitation"
  }.freeze

  DEFAULT_SAVE_THE_DATE_COPY = {
    "eyebrow" => "Save the Date",
    "announcement" => "We are delighted to announce our wedding and would be honored to have you celebrate with us on this special day.",
    "formal_note" => "Formal invitation to follow",
    "signup_eyebrow" => "Stay in Touch",
    "signup_prompt" => "Leave your details and we'll make sure your formal invitation reaches you.",
    "calendar_button_text" => "Add to Calendar",
    "submit_button_text" => "Share My Details"
  }.freeze

  DEFAULT_FAQ = {
    "title" => "FAQ",
    "subtitle" => "Everything you need to know for our big day",
    "questions" => [
      {
        "question" => "What should I wear?",
        "answer" => "We will share dress code details with your invitation."
      }
    ]
  }.freeze

  DEFAULT_WEDDING_PARTY = {
    "title" => "Wedding Party",
    "subtitle" => "The people who've stood by our side through everything",
    "bridesmaids_title" => "Bridesmaids",
    "groomsmen_title" => "Groomsmen",
    "bridesmaids" => [],
    "groomsmen" => []
  }.freeze

  HOMEPAGE_GALLERY_DEFAULT_LIMIT = 6

  # Single source for curated photos: sectioned gallery page + homepage preview.
  DEFAULT_PHOTOS_PAGE = {
    "title" => "Our Photos",
    "subtitle" => "A few of our favourite moments",
    "homepage_enabled" => false,
    "homepage_title" => "Gallery",
    "homepage_limit" => HOMEPAGE_GALLERY_DEFAULT_LIMIT,
    "sections" => []
  }.freeze

  # Only the theme key is seeded: colours, fonts and page toggles are left empty so a
  # wedding that has never opened the theme editor keeps inheriting whatever the
  # chosen theme declares as its defaults.
  DEFAULT_THEME = {
    "key" => SiteThemes::DEFAULT_KEY
  }.freeze

  DEFAULT_NOTIFICATIONS = {
    "reminders" => {
      "enabled" => true,
      "send_time" => "10:00",
      "audience" => "pending_rsvp",
      "channels" => {
        "email" => { "enabled" => true }
      },
      "schedule" => [
        {
          "key" => "week_before",
          "days_before" => 7,
          "channels" => ["email"],
          "email_subject" => "Your wedding RSVP: one week to go"
        },
        {
          "key" => "day_before",
          "days_before" => 1,
          "channels" => ["email"],
          "email_subject" => "Your wedding RSVP: tomorrow is the big day"
        },
        {
          "key" => "day_of",
          "days_before" => 0,
          "channels" => ["email"],
          "email_subject" => "Today is wedding day"
        }
      ]
    }
  }.freeze

  has_one :admin_user, dependent: :destroy, inverse_of: :wedding
  has_many :guests, foreign_key: :wedding_id, primary_key: :id, dependent: :destroy, inverse_of: false
  has_many :households, foreign_key: :wedding_id, primary_key: :id, dependent: :destroy, inverse_of: false
  has_many :save_the_date_signups, foreign_key: :wedding_id, primary_key: :id, dependent: :destroy, inverse_of: false
  has_many :events, foreign_key: :wedding_id, primary_key: :id, dependent: :destroy, inverse_of: false
  has_many :metadata, class_name: "WeddingMetadata", foreign_key: :wedding_id, primary_key: :id,
                       dependent: :destroy, inverse_of: false
  has_many :disposable_photos, foreign_key: :wedding_id, primary_key: :id, dependent: :destroy, inverse_of: false
  has_many :wedding_assets, foreign_key: :wedding_id, primary_key: :id, dependent: :destroy, inverse_of: :wedding

  before_validation :normalize_id
  before_validation :normalize_custom_domain
  before_validation :apply_content_defaults, on: :create

  validates :id, presence: true, uniqueness: true, format: { with: SLUG_FORMAT, message: "must be lowercase letters, numbers, and hyphens" }
  validates :title, presence: true
  validates :custom_domain, uniqueness: true, allow_nil: true
  validate :custom_domain_must_look_like_hostname

  def couple
    {
      "partner1" => partner1,
      "partner2" => partner2,
      "initials" => initials
    }
  end

  def venue
    return {} if venue_name.blank? && venue_city.blank? && venue_region.blank?

    {
      "name" => venue_name,
      "city" => venue_city,
      "region" => venue_region
    }
  end

  # "The Grand Hall, Toronto, Ontario" — the venue as a single readable line.
  def self.venue_label(venue_hash)
    venue_hash.to_h.values_at(*VENUE_LABEL_PARTS).compact_blank.join(", ")
  end

  # True when an entry actually points at a photo, whatever shape it is stored in.
  def self.image_entry?(entry)
    return false if entry.blank?
    return entry.object_key.present? if entry.is_a?(WeddingAsset)

    entry.to_h.values_at(*IMAGE_ENTRY_KEYS).any?(&:present?)
  end

  def venue_label
    self.class.venue_label(venue)
  end

  def rsvp
    rsvp_copy.presence || DEFAULT_RSVP_COPY.deep_dup
  end

  def save_the_date
    DEFAULT_SAVE_THE_DATE_COPY.deep_dup.merge((save_the_date_copy.presence || {}).deep_dup)
  end

  # Canonical gallery content (sections + homepage preview settings).
  # Falls back to legacy `gallery` JSON when photos_page has no sections yet.
  def gallery_content
    page = DEFAULT_PHOTOS_PAGE.deep_dup.merge((photos_page.presence || {}).deep_dup)
    sections = Array(page["sections"])

    if sections.empty?
      legacy = gallery.presence || {}
      legacy_images = Array(legacy["images"]).select { |image| image_entry_present?(image) }
      if legacy_images.any?
        page["sections"] = [{ "title" => legacy["title"].presence || "Gallery", "images" => legacy_images }]
        page["homepage_enabled"] = ActiveModel::Type::Boolean.new.cast(legacy["enabled"])
        page["homepage_title"] = legacy["title"].presence || page["homepage_title"]
      end
    end

    limit = page["homepage_limit"].to_i
    page["homepage_limit"] = limit.positive? ? limit : HOMEPAGE_GALLERY_DEFAULT_LIMIT
    page["sections"] = Array(page["sections"])
    page
  end

  # Sections with their images resolved from the photo library. Library assets come
  # first, followed by any legacy entries that only ever had an external url.
  def gallery_sections
    Array(gallery_content["sections"]).map do |section|
      {
        "title" => section["title"],
        "images" => section_images(section)
      }
    end
  end

  # Assets placed in a `SiteSlots` slot, in the configured order, with ids that no
  # longer resolve dropped and the slot's maximum enforced.
  def placements_for(slot_key)
    slot = SiteSlots.find(slot_key)
    return [] if slot.nil?

    ids = Array(placements.presence&.dig(slot.key)).map(&:to_s)
    ids.filter_map { |id| asset_library_index[id] }.first(slot.max)
  end

  def placement(slot_key)
    placements_for(slot_key).first
  end

  # Homepage hero photo: library placement first, then a legacy inline hero entry.
  def hero_image
    placement("homepage_hero").presence || (self.class.image_entry?(hero) ? hero : nil)
  end

  # Link-preview photo: an explicit share placement, otherwise the hero.
  def share_image
    placement("share_image").presence || hero_image
  end

  # Party member photo: library asset id first, then a legacy inline entry.
  def party_member_image(member)
    data = member.to_h
    if (id = data["asset_id"].presence)
      return asset_library_index[id.to_s]
    end

    self.class.image_entry?(data) ? data : nil
  end

  def homepage_gallery_visible?
    ActiveModel::Type::Boolean.new.cast(gallery_content["homepage_enabled"]) && homepage_gallery_images.any?
  end

  def homepage_gallery_images
    limit = gallery_content["homepage_limit"].to_i
    gallery_sections.flat_map { |section| Array(section["images"]) }.first(limit)
  end

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

  # The resolved website theme. Memoised because a page render reads it many times.
  def site_theme
    @site_theme ||= WeddingTheme.for(self)
  end

  def dispo_photo_style
    value = metadata.find_by(key: PHOTO_STYLE_METADATA_KEY)&.value
    PHOTO_STYLES.include?(value) ? value : DEFAULT_PHOTO_STYLE
  end

  def configured?
    partner1.present? && partner2.present? && date.present?
  end

  def dispo_camera_closes_at
    tz = ActiveSupport::TimeZone[timezone] || Time.zone
    return fallback_dispo_closes_at(tz) if date.blank?

    parsed = tz.parse("#{date} #{ceremony_time}")
    return fallback_dispo_closes_at(tz) if parsed.blank?

    parsed + wedding_duration_hours.to_i.hours
  rescue ArgumentError, TypeError
    fallback_dispo_closes_at(tz)
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

  def public_host
    custom_domain.presence || AppHost.subdomain_host(id)
  end

  def reload(...)
    @asset_library_index = nil
    @site_theme = nil
    super
  end

  private

  # Memoized so a page rendering several slots and sections costs one query.
  def asset_library_index
    @asset_library_index ||= wedding_assets.ordered.index_by { |asset| asset.id.to_s }
  end

  def section_images(section)
    from_library = Array(section["asset_ids"]).filter_map { |id| asset_library_index[id.to_s] }
    legacy = Array(section["images"]).select { |image| image_entry_present?(image) }

    from_library + legacy
  end

  def image_entry_present?(image)
    self.class.image_entry?(image)
  end

  def normalize_id
    self.id = id.to_s.strip.downcase.presence
  end

  def normalize_custom_domain
    value = custom_domain.to_s.strip.downcase.presence
    value = value.delete_prefix("http://").delete_prefix("https://") if value
    value = value.split("/").first if value
    self.custom_domain = value
  end

  def apply_content_defaults
    self.story = DEFAULT_STORY.deep_dup if story.blank?
    self.hero = DEFAULT_HERO.deep_dup if hero.blank?
    self.gallery = DEFAULT_GALLERY.deep_dup if gallery.blank?
    self.rsvp_copy = DEFAULT_RSVP_COPY.deep_dup if rsvp_copy.blank?
    self.save_the_date_copy = DEFAULT_SAVE_THE_DATE_COPY.deep_dup if save_the_date_copy.blank?
    self.faq = DEFAULT_FAQ.deep_dup if faq.blank?
    self.wedding_party = DEFAULT_WEDDING_PARTY.deep_dup if wedding_party.blank?
    self.photos_page = DEFAULT_PHOTOS_PAGE.deep_dup if photos_page.blank?
    self.notifications = DEFAULT_NOTIFICATIONS.deep_dup if notifications.blank?
    self.theme = DEFAULT_THEME.deep_dup if theme.blank?
    self.meal_options = [] if meal_options.nil?
  end

  def custom_domain_must_look_like_hostname
    return if custom_domain.blank?
    return if custom_domain.match?(/\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)+\z/)

    errors.add(:custom_domain, "must be a valid hostname")
  end

  def fallback_dispo_closes_at(tz)
    return tz.local(date.year, date.month, date.day) + 1.day if date.present?

    Time.current + 1.day
  end
end

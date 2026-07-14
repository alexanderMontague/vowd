class Wedding < ApplicationRecord
  self.primary_key = "id"

  PHOTO_STYLES = %w[original retro bw].freeze
  DEFAULT_PHOTO_STYLE = "retro".freeze
  PHOTO_STYLE_METADATA_KEY = "dispo_photo_style".freeze

  SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  DEFAULT_STORY = {
    "enabled" => false,
    "title" => "Our Story",
    "paragraphs" => [],
    "closing" => nil
  }.freeze

  DEFAULT_HERO = {
    "tagline" => "Request the Honour of Your Presence",
    "object_key" => nil,
    "image_url" => ""
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

  DEFAULT_PHOTOS_PAGE = {
    "title" => "Our Photos",
    "subtitle" => "A few of our favourite moments",
    "sections" => []
  }.freeze

  DEFAULT_NOTIFICATIONS = {
    "reminders" => {
      "enabled" => true,
      "send_time" => "10:00",
      "audience" => "pending_rsvp",
      "channels" => {
        "email" => { "enabled" => true },
        "sms" => { "enabled" => false }
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

  def rsvp
    rsvp_copy.presence || DEFAULT_RSVP_COPY.deep_dup
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

  private

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
    self.faq = DEFAULT_FAQ.deep_dup if faq.blank?
    self.wedding_party = DEFAULT_WEDDING_PARTY.deep_dup if wedding_party.blank?
    self.photos_page = DEFAULT_PHOTOS_PAGE.deep_dup if photos_page.blank?
    self.notifications = DEFAULT_NOTIFICATIONS.deep_dup if notifications.blank?
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

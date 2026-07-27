# What a wedding site says about itself to everything that is not a browser window:
# the card messaging apps and social networks build from a shared link, and the entry
# search engines index. One source of truth so the preview a guest sees matches the
# page it opens.
#
# Turning a stored photo into a URL needs route helpers, so this class only ranks the
# candidate photos and `SiteMetaHelper` resolves the first one that exists.
class SiteMeta
  Image = Data.define(:url, :alt)

  DATE_FORMAT = "%A, %B %-d, %Y".freeze
  TITLE_SEPARATOR = " · ".freeze
  FALLBACK_TITLE = "Wedding".freeze
  FALLBACK_DESCRIPTION = "Wedding details, schedule and RSVP.".freeze

  # Photos that can stand in for a hero the couple has not set, in the order tried.
  FALLBACK_IMAGE_SLOTS = %w[save_the_date_portrait save_the_date_vase].freeze

  def initialize(wedding)
    @wedding = wedding
  end

  attr_reader :wedding

  # The couple and the day, which is what a preview headline is asked to answer.
  def title
    return FALLBACK_TITLE if wedding.blank?

    [site_name, formatted_date].compact_blank.join(TITLE_SEPARATOR)
  end

  def site_name
    wedding&.title.presence || FALLBACK_TITLE
  end

  def description
    invitation_line.presence || tagline.presence || FALLBACK_DESCRIPTION
  end

  # Photos ranked best first, so a couple who has filled in only one part of their
  # site still gets a picture on the card.
  def image_candidates
    return [] if wedding.blank?

    [wedding.hero_image, *fallback_slot_photos, first_gallery_photo].select { |entry| Wedding.image_entry?(entry) }
  end

  private

  def formatted_date
    wedding.date&.strftime(DATE_FORMAT)
  end

  def invitation_line
    return if wedding.blank?

    venue = wedding.venue_label
    details = []
    details << "on #{formatted_date}" if formatted_date.present?
    details << "at #{venue}" if venue.present?
    return if details.empty?

    "Join us #{details.join(' ')}."
  end

  def tagline
    return if wedding.blank?

    wedding.hero.to_h["tagline"]
  end

  def fallback_slot_photos
    FALLBACK_IMAGE_SLOTS.map { |slot| wedding.placement(slot) }
  end

  def first_gallery_photo
    wedding.homepage_gallery_images.first
  end
end

module WeddingHelper
  # "Alex & Sam", "Alex and Sam" and "Alex + Sam" all describe two people.
  COUPLE_SEPARATOR = /\s*(?:&|\+|\band\b)\s*/i
  MONOGRAM_LENGTH = 2

  def full_venue_name(venue_hash)
    Wedding.venue_label(venue_hash)
  end

  # A monogram for ornament that carries lettering, such as a cameo or a seal.
  # Falls back to the leading words of the title when it does not name a couple.
  def wedding_monogram(wedding)
    parts = wedding&.title.to_s.split(COUPLE_SEPARATOR).map(&:strip).reject(&:blank?)
    parts = parts.first.to_s.split(/\s+/) if parts.one?

    parts.filter_map { |part| part[0]&.upcase }.first(MONOGRAM_LENGTH).join
  end

  def wedding_datetime_iso(wedding)
    return unless wedding&.date

    tz = ActiveSupport::TimeZone[wedding.timezone] || Time.zone
    time_str = wedding.ceremony_time.presence || "12:00 PM"
    tz.parse("#{wedding.date} #{time_str}").iso8601
  rescue ArgumentError, TypeError
    wedding.date.beginning_of_day.in_time_zone(tz).iso8601
  end
end

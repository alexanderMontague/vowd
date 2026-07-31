module ApplicationHelper
  # Drift speeds for the floating photo positions defined in the stylesheet.
  # Alternating signs give the cluster a sense of depth.
  FLOATING_PHOTO_SPEEDS = [0.16, -0.11, 0.22, -0.14, 0.18].freeze

  HOUR_WORDS = {
    1 => "one", 2 => "two", 3 => "three", 4 => "four", 5 => "five", 6 => "six",
    7 => "seven", 8 => "eight", 9 => "nine", 10 => "ten", 11 => "eleven", 12 => "twelve"
  }.freeze

  MINUTE_WORDS = {
    1 => "one", 2 => "two", 3 => "three", 4 => "four", 5 => "five", 6 => "six",
    7 => "seven", 8 => "eight", 9 => "nine", 10 => "ten", 11 => "eleven", 12 => "twelve",
    13 => "thirteen", 14 => "fourteen", 15 => "fifteen", 16 => "sixteen", 17 => "seventeen",
    18 => "eighteen", 19 => "nineteen", 20 => "twenty", 21 => "twenty-one", 22 => "twenty-two",
    23 => "twenty-three", 24 => "twenty-four", 25 => "twenty-five", 26 => "twenty-six",
    27 => "twenty-seven", 28 => "twenty-eight", 29 => "twenty-nine", 30 => "thirty",
    31 => "thirty-one", 32 => "thirty-two", 33 => "thirty-three", 34 => "thirty-four",
    35 => "thirty-five", 36 => "thirty-six", 37 => "thirty-seven", 38 => "thirty-eight",
    39 => "thirty-nine", 40 => "forty", 41 => "forty-one", 42 => "forty-two",
    43 => "forty-three", 44 => "forty-four", 45 => "forty-five", 46 => "forty-six",
    47 => "forty-seven", 48 => "forty-eight", 49 => "forty-nine", 50 => "fifty",
    51 => "fifty-one", 52 => "fifty-two", 53 => "fifty-three", 54 => "fifty-four",
    55 => "fifty-five", 56 => "fifty-six", 57 => "fifty-seven", 58 => "fifty-eight",
    59 => "fifty-nine"
  }.freeze

  def page_title(title = nil)
    base_title = current_wedding&.title || "Wedding"
    title.present? ? "#{title} | #{base_title}" : base_title
  end

  def format_date(date)
    raise "Missing date" if date.blank?

    date = Date.parse(date) if date.is_a?(String)

    date.strftime("%B %d, %Y")
  end

  def format_datetime(datetime)
    return nil unless datetime.present? && datetime.is_a?(String)

    datetime = DateTime.parse(datetime)

    datetime.strftime("%B %d, %Y at %I:%M %p")
  end

  def format_date_invitation(date)
    raise "Missing date" if date.blank?

    date = Date.parse(date) if date.is_a?(String)
    date.strftime("%A, %B #{date.day}, %Y").downcase
  end

  def format_date_short(date)
    raise "Missing date" if date.blank?

    date = Date.parse(date) if date.is_a?(String)

    date.strftime("%m.%d.%Y")
  end

  # Weekday spelled out; day, month, and year numeric — e.g. "Saturday, 10 May 2027".
  def format_date_elegant(date)
    raise "Missing date" if date.blank?

    date = Date.parse(date) if date.is_a?(String)

    "#{date.strftime('%A')}, #{date.day} #{date.strftime('%B')} #{date.year}"
  end

  # Spells ceremony times for invitation surfaces — e.g. "four thirty in the afternoon".
  def format_time_elegant(time_value)
    time = parse_display_time(time_value)
    return if time.nil?

    hour = time.hour % 12
    hour = 12 if hour.zero?
    hour_word = HOUR_WORDS.fetch(hour)
    period = time_of_day_period(time.hour)

    clock = if time.min.zero?
              "#{hour_word} o'clock"
            else
              "#{hour_word} #{MINUTE_WORDS.fetch(time.min)}"
            end

    "#{clock} in the #{period}"
  end

  def rsvp_status_badge(status)
    css_class = case status
                when "accepted" then "badge-success"
                when "declined" then "badge-danger"
                else "badge-warning"
                end

    content_tag(:span, status.capitalize, class: "badge #{css_class}")
  end

  def calendar_url
    return "#" unless current_wedding&.event_starts_at

    user_agent = request&.user_agent&.to_s&.downcase || ""

    if ios_device?(user_agent) || macos_device?(user_agent)
      calendar_ics_url
    else
      google_calendar_url
    end
  end

  def calendar_ics_url
    public_calendar_ics_path(format: :ics)
  end

  def botanical_svg(name, css_class: nil)
    path = Rails.root.join("app/assets/images/botanical/#{name}.svg")
    svg = File.read(path)
    svg = svg.gsub('fill="#000000"', 'fill="currentColor"')
    svg = svg.sub("<svg ", %(<svg class="#{css_class}" )) if css_class.present?
    svg.html_safe
  end

  def theme_svg(theme_key, name, css_class: nil)
    path = Rails.root.join("app/assets/images/themes/#{theme_key}/#{name}.svg")
    return "".html_safe unless path.file?

    svg = File.read(path)
    svg = svg.sub("<svg ", %(<svg class="#{css_class}" )) if css_class.present?
    svg.html_safe
  end

  # Illustrated WebP ornament for a theme (fern corners, ceramic frames, etc.).
  # Falls back to the theme SVG when no raster asset exists.
  def theme_ornament(theme_key, name, css_class: nil, alt: "")
    relative = "themes/#{theme_key}/#{name}.webp"
    absolute = Rails.root.join("app/assets/images", relative)
    if absolute.file?
      return image_tag(relative, class: css_class, alt: alt, aria: { hidden: alt.blank? },
                       loading: "lazy", decoding: "async")
    end

    theme_svg(theme_key, name, css_class: css_class)
  end

  def admin_nav_link(label, path, active_prefixes: [path], exact: false)
    active = if exact
               request.path == path
             else
               active_prefixes.any? { |prefix| request.path.start_with?(prefix) }
             end
    css_class = "admin-side-nav-link"
    css_class = "#{css_class} admin-side-nav-link-active" if active

    link_to(label, path, class: css_class)
  end

  def admin_nav_section(label)
    content_tag(:p, label, class: "admin-side-nav-section")
  end

  def billing_status_badge_class(status)
    case status.to_s
    when "active" then "badge-success"
    when "trialing" then "badge-neutral"
    when "past_due" then "badge-warning"
    else "badge-danger"
    end
  end


  # Resolves wedding content images: library assets and uploaded object keys via the
  # app proxy, or legacy absolute URLs.
  def wedding_asset_url(entry)
    return if entry.blank?

    data = wedding_asset_attributes(entry)
    object_key = data[:object_key].presence
    return public_site_asset_path(object_key: object_key) if object_key.present?

    data[:url].presence || data[:image_url].presence
  end

  def wedding_asset_thumbnail_url(entry)
    return if entry.blank?

    object_key = wedding_asset_attributes(entry)[:object_key].presence
    return wedding_asset_url(entry) if object_key.blank?

    public_site_asset_path(object_key: WeddingAssets::ObjectKeyBuilder.thumbnail_key(object_key))
  end

  def wedding_asset_alt(entry)
    return "" if entry.blank?

    wedding_asset_attributes(entry)[:alt].to_s
  end

  # Single lookup point for decorative components so a future theme can swap the
  # whole decor set without touching the pages that render them.
  def decor_partial(name)
    "public/decor/#{name}"
  end

  def floating_photo_layers(assets)
    Array(assets).first(FLOATING_PHOTO_SPEEDS.size).zip(FLOATING_PHOTO_SPEEDS)
  end

  private

  def wedding_asset_attributes(entry)
    case entry
    when WeddingAsset then { object_key: entry.object_key, alt: entry.alt }.with_indifferent_access
    when Hash then entry.with_indifferent_access
    else { url: entry.to_s }.with_indifferent_access
    end
  end

  def ios_device?(user_agent)
    user_agent.match?(/iphone|ipad|ipod/)
  end

  def macos_device?(user_agent)
    user_agent.match?(/macintosh|mac os x/) && !user_agent.match?(/iphone|ipad|ipod/)
  end

  def google_calendar_url
    start_time = current_wedding.event_starts_at
    end_time = current_wedding.event_ends_at
    return "#" unless start_time && end_time

    title = ERB::Util.url_encode(current_wedding.title)
    details = ERB::Util.url_encode("Join us for our wedding celebration!")
    location = current_wedding.venue ? ERB::Util.url_encode(full_venue_name(current_wedding.venue)) : ""
    dates = "#{start_time.strftime('%Y%m%dT%H%M%S')}/#{end_time.strftime('%Y%m%dT%H%M%S')}"

    "https://calendar.google.com/calendar/render?action=TEMPLATE&text=#{title}&dates=#{dates}&details=#{details}&location=#{location}"
  end

  def parse_display_time(value)
    case value
    when Time, ActiveSupport::TimeWithZone then value
    when DateTime then value.to_time
    when String
      stripped = value.to_s.strip
      return if stripped.blank?

      Time.zone.parse(stripped)
    end
  rescue ArgumentError, TypeError
    nil
  end

  def time_of_day_period(hour)
    case hour
    when 0...12 then "morning"
    when 12...17 then "afternoon"
    when 17...21 then "evening"
    else "night"
    end
  end
end

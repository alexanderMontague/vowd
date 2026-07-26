module ApplicationHelper
  # Drift speeds for the floating photo positions defined in the stylesheet.
  # Alternating signs give the cluster a sense of depth.
  FLOATING_PHOTO_SPEEDS = [0.16, -0.11, 0.22].freeze

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

  def format_date_elegant(date)
    raise "Missing date" if date.blank?

    date = Date.parse(date) if date.is_a?(String)

    day_words = {
      1 => "First", 2 => "Second", 3 => "Third", 4 => "Fourth", 5 => "Fifth",
      6 => "Sixth", 7 => "Seventh", 8 => "Eighth", 9 => "Ninth", 10 => "Tenth",
      11 => "Eleventh", 12 => "Twelfth", 13 => "Thirteenth", 14 => "Fourteenth", 15 => "Fifteenth",
      16 => "Sixteenth", 17 => "Seventeenth", 18 => "Eighteenth", 19 => "Nineteenth", 20 => "Twentieth",
      21 => "Twenty-First", 22 => "Twenty-Second", 23 => "Twenty-Third", 24 => "Twenty-Fourth", 25 => "Twenty-Fifth",
      26 => "Twenty-Sixth", 27 => "Twenty-Seventh", 28 => "Twenty-Eighth", 29 => "Twenty-Ninth", 30 => "Thirtieth",
      31 => "Thirty-First"
    }

    year_words = (2024..2035).to_h do |y|
      ones = %w[Twenty Twenty-One Twenty-Two Twenty-Three Twenty-Four Twenty-Five Twenty-Six Twenty-Seven Twenty-Eight
                Twenty-Nine Thirty Thirty-One Thirty-Two Thirty-Three Thirty-Four Thirty-Five]
      [y, "Two Thousand #{ones[y - 2020]}"]
    end

    month = date.strftime("%B")
    day = day_words[date.day] || date.day.to_s
    year = year_words[date.year] || date.year.to_s

    "#{month} #{day}, #{year}"
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
    return "#" unless current_wedding&.date

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
    wedding_date = current_wedding.date
    title = ERB::Util.url_encode(current_wedding.title)
    details = ERB::Util.url_encode("Join us for our wedding celebration!")
    location = current_wedding.venue ? ERB::Util.url_encode(full_venue_name(current_wedding.venue)) : ""

    start_time = wedding_date.beginning_of_day
    end_time = wedding_date.end_of_day

    dates = "#{start_time.strftime('%Y%m%dT%H%M%S')}/#{end_time.strftime('%Y%m%dT%H%M%S')}"

    "https://calendar.google.com/calendar/render?action=TEMPLATE&text=#{title}&dates=#{dates}&details=#{details}&location=#{location}"
  end
end

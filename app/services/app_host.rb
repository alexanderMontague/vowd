module AppHost
  module_function

  def base_domain
    ENV.fetch("APP_BASE_DOMAIN", "localhost").to_s.strip.downcase.split(":").first
  end

  def normalize_host(host)
    host.to_s.strip.downcase.split(":").first
  end

  def platform_host?(host)
    normalized = normalize_host(host)
    return true if normalized == base_domain
    return true if normalized == "www.#{base_domain}"
    return true if local_dev_apex?(normalized)

    false
  end

  def subdomain_host(slug)
    "#{slug}.#{base_domain}"
  end

  def extract_subdomain(host)
    normalized = normalize_host(host)
    return nil if platform_host?(normalized)

    suffix = ".#{base_domain}"
    return nil unless normalized.end_with?(suffix)

    slug = normalized.delete_suffix(suffix)
    return nil if slug.blank? || slug.include?(".")

    slug
  end

  # Session cookie Domain attribute for this request host.
  # - Platform apex + wedding subdomains share `.APP_BASE_DOMAIN` so login
  #   survives redirects between them.
  # - Custom domains get a host-only cookie (`nil`). A Domain=.APP_BASE_DOMAIN
  #   cookie is rejected by the browser on those hosts, which breaks CSRF on
  #   guest forms (save the date, RSVP, etc.).
  def session_cookie_domain(host)
    normalized = normalize_host(host)
    base = base_domain
    return nil if base.blank? || %w[localhost 127.0.0.1].include?(base)

    if normalized == base || normalized == "www.#{base}" || normalized.end_with?(".#{base}")
      ".#{base}"
    end
  end

  # Always the slug subdomain — session cookies for APP_BASE_DOMAIN hosts are
  # shared across that tree; custom domains use a separate host-only cookie.
  def wedding_admin_url(wedding, path: "/admin")
    absolute_url(host: subdomain_host(wedding.id), path: path)
  end

  # The guest-facing origin, so links handed to guests (printed QR codes, emails)
  # honour a wedding's custom domain instead of leaking the admin host.
  def wedding_public_url(wedding, path: "/")
    absolute_url(host: wedding.public_host, path: path)
  end

  def absolute_url(host:, path: "/")
    port = ENV["APP_PORT"].presence
    protocol = Rails.env.local? ? "http" : "https"
    authority = port.present? ? "#{host}:#{port}" : host
    "#{protocol}://#{authority}#{path}"
  end

  def local_dev_apex?(normalized)
    return false unless Rails.env.local?

    %w[localhost 127.0.0.1].include?(normalized)
  end
end

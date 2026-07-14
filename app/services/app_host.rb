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

  def wedding_admin_url(wedding, path: "/admin")
    host = wedding.public_host
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

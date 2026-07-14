class TenantResolver
  def self.call(host:)
    new(host:).resolve
  end

  def initialize(host:)
    @host = AppHost.normalize_host(host)
  end

  def resolve
    return nil if AppHost.platform_host?(@host)

    slug = AppHost.extract_subdomain(@host)
    return Wedding.find_by(id: slug) if slug.present?

    Wedding.find_by(custom_domain: @host)
  end
end

class WeddingHostConstraint
  def self.matches?(request)
    TenantResolver.call(host: request.host).present?
  end
end

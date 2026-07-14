class PlatformHostConstraint
  def self.matches?(request)
    AppHost.platform_host?(request.host)
  end
end

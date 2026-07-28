# Admin sessions share the APP_BASE_DOMAIN cookie tree. Custom-domain hosts
# use a separate host-only cookie, so admin traffic always uses the slug
# subdomain where that shared session lives.
module AdminCanonicalHost
  extend ActiveSupport::Concern

  included do
    prepend_before_action :redirect_admin_to_canonical_host
  end

  private

  def redirect_admin_to_canonical_host
    wedding = TenantResolver.call(host: request.host)
    return unless wedding

    canonical_host = AppHost.subdomain_host(wedding.id)
    return if AppHost.normalize_host(request.host) == canonical_host

    redirect_to AppHost.wedding_admin_url(wedding, path: request.fullpath),
                allow_other_host: true,
                status: :temporary_redirect
  end
end

require "test_helper"

class TenantResolverTest < ActiveSupport::TestCase
  setup do
    @wedding = create_wedding(id: "acme-wedding", custom_domain: "acme.example.com")
  end

  test "resolves wedding by subdomain" do
    host = AppHost.subdomain_host(@wedding.id)

    assert_equal @wedding, TenantResolver.call(host:)
  end

  test "resolves wedding by custom domain" do
    assert_equal @wedding, TenantResolver.call(host: "acme.example.com")
  end

  test "returns nil for platform host" do
    assert_nil TenantResolver.call(host: AppHost.base_domain)
    assert_nil TenantResolver.call(host: "www.#{AppHost.base_domain}")
  end

  test "returns nil for unknown subdomain" do
    assert_nil TenantResolver.call(host: AppHost.subdomain_host("missing-wedding"))
  end
end

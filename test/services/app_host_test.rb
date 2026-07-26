require "test_helper"

class AppHostTest < ActiveSupport::TestCase
  test "wedding_admin_url uses slug subdomain even when custom domain is set" do
    wedding = create_wedding(id: "acme-wedding", custom_domain: "acme.example.com")

    assert_equal "http://acme-wedding.example.test:3003/admin",
                 AppHost.wedding_admin_url(wedding)
    assert_equal "http://acme-wedding.example.test:3003/admin/website",
                 AppHost.wedding_admin_url(wedding, path: "/admin/website")
  end

  test "wedding_admin_url uses slug subdomain when no custom domain" do
    wedding = create_wedding(id: "plain-wedding")

    assert_equal "http://plain-wedding.example.test:3003/admin",
                 AppHost.wedding_admin_url(wedding)
  end

  test "wedding_public_url prefers the custom domain so guest links stay on brand" do
    wedding = create_wedding(id: "acme-wedding", custom_domain: "acme.example.com")

    assert_equal "http://acme.example.com:3003/dispo",
                 AppHost.wedding_public_url(wedding, path: "/dispo")
  end

  test "wedding_public_url falls back to the slug subdomain" do
    wedding = create_wedding(id: "plain-wedding")

    assert_equal "http://plain-wedding.example.test:3003/dispo",
                 AppHost.wedding_public_url(wedding, path: "/dispo")
  end
end

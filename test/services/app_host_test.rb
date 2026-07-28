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

  test "session_cookie_domain shares the base domain across platform and subdomains" do
    assert_equal ".example.test", AppHost.session_cookie_domain("example.test")
    assert_equal ".example.test", AppHost.session_cookie_domain("www.example.test")
    assert_equal ".example.test", AppHost.session_cookie_domain("acme-wedding.example.test")
  end

  test "session_cookie_domain is host-only on custom domains" do
    assert_nil AppHost.session_cookie_domain("acme.example.com")
    assert_nil AppHost.session_cookie_domain("photos.brittandalex.com")
  end

  test "session_cookie_domain stays host-only for bare localhost" do
    with_env("APP_BASE_DOMAIN" => "localhost") do
      assert_nil AppHost.session_cookie_domain("localhost")
      assert_nil AppHost.session_cookie_domain("127.0.0.1")
    end
  end
end

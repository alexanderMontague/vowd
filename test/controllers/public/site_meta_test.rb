require "test_helper"

class Public::SiteMetaTest < ActionDispatch::IntegrationTest
  setup do
    @wedding = create_wedding(
      title: "Britt & Alex",
      date: Date.new(2027, 7, 10),
      venue_name: "The Grand Hall",
      venue_city: "Toronto",
      venue_region: "Ontario"
    )
    host_wedding!(@wedding)
  end

  test "the homepage shares the couple, the day and the hero photo" do
    @wedding.update!(hero: { "tagline" => "Hello", "object_key" => hero_object_key })

    get root_path

    assert_response :success
    assert_meta_property "og:title", "Britt & Alex · Saturday, July 10, 2027"
    assert_meta_property "og:description", "Join us on Saturday, July 10, 2027 at The Grand Hall, Toronto, Ontario."
    assert_meta_property "og:site_name", "Britt & Alex"
    assert_meta_property "og:url", absolute_url(root_path)
    assert_meta_property "og:image", absolute_url(public_site_asset_path(object_key: hero_object_key))
    assert_select "title", "Britt & Alex · Saturday, July 10, 2027"
  end

  test "the preview image is an absolute url on every page a guest can share" do
    @wedding.update!(hero: { "object_key" => hero_object_key })
    expected = absolute_url(public_site_asset_path(object_key: hero_object_key))

    get public_faq_path

    assert_meta_property "og:image", expected
    assert_meta_name "twitter:image", expected
    assert_meta_name "twitter:card", "summary_large_image"
    assert_meta_property "og:url", absolute_url(public_faq_path)
  end

  test "an explicit share image is preferred over the hero for og:image" do
    hero = @wedding.wedding_assets.create!(
      object_key: "#{Rails.env}/#{@wedding.id}/site/photos/hero.webp",
      content_type: "image/webp",
      byte_size: 2048
    )
    share = @wedding.wedding_assets.create!(
      object_key: "#{Rails.env}/#{@wedding.id}/site/photos/share.webp",
      content_type: "image/webp",
      byte_size: 2048
    )
    @wedding.update!(placements: {
                       "homepage_hero" => [hero.id],
                       "share_image" => [share.id]
                     })

    get root_path

    assert_meta_property "og:image", absolute_url(public_site_asset_path(object_key: share.object_key))
  end

  test "a site with no photos still advertises itself, without an image tag" do
    get root_path

    assert_select "meta[property='og:image']", count: 0
    assert_meta_name "twitter:card", "summary"
    assert_meta_property "og:title", "Britt & Alex · Saturday, July 10, 2027"
  end

  private

  def hero_object_key
    "#{Rails.env}/#{@wedding.id}/site/photos/hero.webp"
  end

  def absolute_url(path)
    "http://#{AppHost.subdomain_host(@wedding.id)}#{path}"
  end

  def assert_meta_property(property, content)
    assert_select "meta[property=?][content=?]", property, content
  end

  def assert_meta_name(name, content)
    assert_select "meta[name=?][content=?]", name, content
  end
end

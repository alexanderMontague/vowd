require "test_helper"

module WeddingAssets
  class LibraryImporterTest < ActiveSupport::TestCase
    setup do
      @wedding = create_wedding
    end

    test "moves inline photos into the library and references them by id" do
      @wedding.update!(photos_page: {
                         "title" => "Our Photos",
                         "sections" => [
                           {
                             "title" => "Engagement",
                             "images" => [
                               { "object_key" => key("one.webp"), "alt" => "On the pier" },
                               { "object_key" => key("two.jpg") }
                             ]
                           }
                         ]
                       })

      assert_equal 2, LibraryImporter.call(wedding: @wedding)

      assets = @wedding.wedding_assets.ordered.to_a
      assert_equal [key("one.webp"), key("two.jpg")], assets.map(&:object_key)
      assert_equal %w[image/webp image/jpeg], assets.map(&:content_type)
      assert_equal "On the pier", assets.first.alt
      assert_equal [0, 1], assets.map(&:position)

      section = @wedding.photos_page["sections"].first
      assert_equal assets.map(&:id), section["asset_ids"]
      assert_empty section["images"]
    end

    test "keeps url-only entries inline because there is nothing to import" do
      @wedding.update!(photos_page: {
                         "sections" => [
                           { "title" => "Engagement", "images" => [{ "url" => "https://example.com/a.jpg", "alt" => "Remote" }] }
                         ]
                       })

      assert_equal 0, LibraryImporter.call(wedding: @wedding)

      section = @wedding.photos_page["sections"].first
      assert_empty section["asset_ids"]
      assert_equal "https://example.com/a.jpg", section["images"].first["url"]
    end

    test "is idempotent" do
      @wedding.update!(photos_page: {
                         "sections" => [{ "title" => "Engagement", "images" => [{ "object_key" => key("one.webp") }] }]
                       })

      assert_equal 1, LibraryImporter.call(wedding: @wedding)
      asset_ids = @wedding.photos_page["sections"].first["asset_ids"]

      assert_equal 0, LibraryImporter.call(wedding: @wedding)
      assert_equal 1, @wedding.wedding_assets.count
      assert_equal asset_ids, @wedding.photos_page["sections"].first["asset_ids"]
    end

    test "imports sections that only exist on the legacy gallery column" do
      @wedding.update!(
        photos_page: {},
        gallery: { "title" => "Gallery", "images" => [{ "object_key" => key("legacy.webp") }] }
      )

      assert_equal 1, LibraryImporter.call(wedding: @wedding)
      assert_equal [key("legacy.webp")], @wedding.wedding_assets.pluck(:object_key)
      assert_equal 1, @wedding.photos_page["sections"].first["asset_ids"].size
    end

    test "imports a hero object key into the library and homepage_hero placement" do
      @wedding.update!(hero: { "tagline" => "Hello", "object_key" => key("hero.webp") })

      assert_equal 1, LibraryImporter.call(wedding: @wedding)

      asset = @wedding.wedding_assets.sole
      assert_equal key("hero.webp"), asset.object_key
      assert_equal [asset.id], @wedding.placements["homepage_hero"]
      assert_equal "Hello", @wedding.hero["tagline"]
      assert_nil @wedding.hero["object_key"]
      assert_equal asset, @wedding.hero_image
    end

    test "imports party member photos as library asset ids" do
      @wedding.update!(wedding_party: {
                         "title" => "Party",
                         "bridesmaids" => [{ "name" => "Sam", "object_key" => key("sam.webp") }],
                         "groomsmen" => []
                       })

      assert_equal 1, LibraryImporter.call(wedding: @wedding)

      member = @wedding.wedding_party["bridesmaids"].first
      asset = @wedding.wedding_assets.sole
      assert_equal asset.id, member["asset_id"]
      assert_nil member["object_key"]
      assert_equal asset, @wedding.party_member_image(member)
    end

    test "leaves weddings without photos untouched" do
      assert_equal 0, LibraryImporter.call(wedding: @wedding)
      assert_empty @wedding.wedding_assets
    end

    private

    def key(name)
      "#{Rails.env}/#{@wedding.id}/site/photos/#{name}"
    end
  end
end

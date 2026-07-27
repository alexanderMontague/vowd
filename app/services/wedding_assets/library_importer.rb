module WeddingAssets
  # Moves photos that used to live inline in wedding JSON into the photo library,
  # rewriting each reference to a library asset id. Entries that only ever had an
  # external url stay inline because there is nothing to import.
  #
  # Idempotent: an object key already in the library is reused, not duplicated.
  class LibraryImporter
    def self.call(wedding:)
      new(wedding: wedding).call
    end

    def initialize(wedding:)
      @wedding = wedding
      @imported = 0
    end

    # Returns the number of library assets created.
    def call
      page = @wedding.gallery_content
      page["sections"] = Array(page["sections"]).map { |section| rewrite_section(section) }
      hero = rewrite_hero(@wedding.hero.presence || {})
      party = rewrite_party(@wedding.wedding_party.presence || {})
      placements = rewrite_hero_placement(@wedding.placements.presence || {}, hero)

      @wedding.update!(
        photos_page: page,
        hero: hero,
        wedding_party: party,
        placements: placements
      )
      @wedding.reload
      @imported
    end

    private

    def rewrite_section(section)
      imported_ids, inline = partition_images(section["images"])
      existing_ids = Array(section["asset_ids"]).map(&:to_s)

      {
        "title" => section["title"].to_s,
        "asset_ids" => (existing_ids + imported_ids).uniq,
        "images" => inline
      }
    end

    def rewrite_hero(raw)
      data = raw.to_h
      hero = { "tagline" => data["tagline"].to_s }

      if data["asset_id"].present?
        hero["asset_id"] = data["asset_id"].to_s
      elsif importable?(data["object_key"])
        hero["asset_id"] = import(data).id
      elsif external?(data)
        hero["image_url"] = (data["image_url"].presence || data["url"]).to_s
      end

      hero
    end

    def rewrite_hero_placement(placements, hero)
      result = placements.deep_dup
      asset_id = hero.delete("asset_id")
      existing = Array(result["homepage_hero"]).map(&:to_s).reject(&:blank?)
      result["homepage_hero"] = [asset_id] if existing.empty? && asset_id.present?
      result
    end

    def rewrite_party(raw)
      data = raw.to_h
      {
        "title" => data["title"].to_s,
        "subtitle" => data["subtitle"].to_s,
        "bridesmaids_title" => data["bridesmaids_title"].to_s,
        "groomsmen_title" => data["groomsmen_title"].to_s,
        "bridesmaids" => Array(data["bridesmaids"]).map { |member| rewrite_party_member(member) },
        "groomsmen" => Array(data["groomsmen"]).map { |member| rewrite_party_member(member) }
      }
    end

    def rewrite_party_member(raw)
      data = raw.to_h
      member = {
        "name" => data["name"].to_s,
        "role" => data["role"].to_s,
        "relation" => data["relation"].to_s
      }

      if data["asset_id"].present?
        member["asset_id"] = data["asset_id"].to_s
      elsif importable?(data["object_key"])
        member["asset_id"] = import(data).id
      elsif external?(data)
        member["image_url"] = (data["image_url"].presence || data["url"]).to_s
      end

      member
    end

    def partition_images(images)
      asset_ids = []
      inline = []

      Array(images).each do |image|
        entry = image.to_h
        if importable?(entry["object_key"])
          asset_ids << import(entry).id
        elsif external?(entry)
          inline << entry
        end
      end

      [asset_ids, inline]
    end

    def external?(entry)
      entry["url"].present? || entry["image_url"].present?
    end

    def importable?(object_key)
      object_key.present? && Uploader::CONTENT_TYPES.include?(content_type_for(object_key))
    end

    def import(entry)
      object_key = entry["object_key"].to_s
      existing = @wedding.wedding_assets.find_by(object_key: object_key)
      return existing if existing

      @imported += 1
      @wedding.wedding_assets.create!(
        object_key: object_key,
        content_type: content_type_for(object_key),
        alt: entry["alt"].presence,
        position: next_position
      )
    end

    def next_position
      @next_position = (@next_position || @wedding.wedding_assets.maximum(:position) || -1) + 1
    end

    def content_type_for(object_key)
      ObjectKeyBuilder.content_type_for(object_key)
    end
  end
end

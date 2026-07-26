module WeddingAssets
  # Moves photos that used to live inline in the `photos_page` JSON into the photo
  # library, rewriting each section to reference library asset ids. Entries that only
  # ever had an external url stay inline because there is nothing to import.
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

      @wedding.update!(photos_page: page)
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

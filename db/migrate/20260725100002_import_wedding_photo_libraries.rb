class ImportWeddingPhotoLibraries < ActiveRecord::Migration[7.1]
  def up
    Wedding.find_each do |wedding|
      imported = WeddingAssets::LibraryImporter.call(wedding: wedding)
      say "#{wedding.id}: imported #{imported} photo(s) into the library" if imported.positive?
    end
  end

  def down
    # Sections keep their inline `images` only for url-only entries, so the object keys
    # that moved into the library cannot be reconstructed from the JSON alone.
    raise ActiveRecord::IrreversibleMigration
  end
end

class ImportHeroAndPartyLibraryPlacements < ActiveRecord::Migration[7.1]
  def up
    Wedding.find_each do |wedding|
      imported = WeddingAssets::LibraryImporter.call(wedding: wedding)
      say "#{wedding.id}: imported #{imported} photo(s) into the library" if imported.positive?
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

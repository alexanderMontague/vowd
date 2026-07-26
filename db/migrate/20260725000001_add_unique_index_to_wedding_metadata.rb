class AddUniqueIndexToWeddingMetadata < ActiveRecord::Migration[7.1]
  # Migration-local model so app-level validations and callbacks cannot interfere.
  class MetadataRow < ActiveRecord::Base
    self.table_name = "wedding_metadata"
  end

  def up
    drop_duplicate_rows
    add_index :wedding_metadata, %i[wedding_id key], unique: true
  end

  def down
    remove_index :wedding_metadata, %i[wedding_id key]
  end

  private

  # `Wedding#feature_flag` reads a single row per key, so duplicates make a flag
  # resolve non-deterministically. Keep the most recently updated row.
  def drop_duplicate_rows
    duplicate_keys = MetadataRow.group(:wedding_id, :key).having("COUNT(*) > 1").pluck(:wedding_id, :key)

    duplicate_keys.each do |wedding_id, key|
      stale_ids = MetadataRow.where(wedding_id: wedding_id, key: key)
                             .order(updated_at: :desc, id: :desc)
                             .offset(1)
                             .pluck(:id)

      MetadataRow.where(id: stale_ids).delete_all
    end
  end
end

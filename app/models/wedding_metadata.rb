class WeddingMetadata < ApplicationRecord
  include UuidPrimaryKey
  include WeddingScoped

  validates :key, presence: true, uniqueness: { scope: :wedding_id }
  validates :value, presence: true
end

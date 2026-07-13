class DisposablePhoto < ApplicationRecord
  include UuidPrimaryKey

  CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  belongs_to :guest, optional: true

  validates :wedding_id, presence: true
  validates :object_key, presence: true, uniqueness: true
  validates :content_type, inclusion: { in: CONTENT_TYPES }
  validates :byte_size, numericality: { greater_than: 0 }

  scope :recent_first, -> { order(created_at: :desc) }

  after_destroy_commit :delete_remote_asset

  # Suggested filename for downloads, e.g. "montague-20260710-231500.jpg".
  def download_filename(prefix:)
    extension = File.extname(object_key.to_s).presence || ".jpg"
    timestamp = (captured_at || created_at)&.strftime("%Y%m%d-%H%M%S")
    [prefix.presence, timestamp].compact.join("-") + extension
  end

  private

  def delete_remote_asset
    return if object_key.blank?

    DisposableCamera::StorageClient.delete!(object_key: object_key)
  rescue Aws::S3::Errors::ServiceError, Seahorse::Client::NetworkingError => e
    Rails.logger.error("Disposable photo remote delete failed for key=#{object_key}: #{e.class}: #{e.message}")
  end
end

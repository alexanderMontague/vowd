class WeddingAsset < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :wedding, inverse_of: :wedding_assets

  validates :object_key, presence: true, uniqueness: true
  validates :content_type, inclusion: { in: WeddingAssets::Uploader::STORED_CONTENT_TYPES }
  # Assets imported from legacy JSON content predate byte size tracking.
  validates :byte_size, numericality: { greater_than: 0 }, allow_nil: true

  scope :ordered, -> { order(:position, :created_at) }
  scope :images, -> {
    where(content_type: WeddingAssets::Uploader::IMAGE_CONTENT_TYPES + [WeddingAssets::ImageCompressor::OUTPUT_CONTENT_TYPE])
  }
  scope :videos, -> { where(content_type: WeddingAssets::Uploader::VIDEO_CONTENT_TYPES + [WeddingAssets::VideoProcessor::OUTPUT_CONTENT_TYPE]) }

  after_destroy_commit :delete_remote_objects

  def thumbnail_object_key
    WeddingAssets::ObjectKeyBuilder.thumbnail_key(object_key)
  end

  def video?
    WeddingAssets::Uploader::VIDEO_CONTENT_TYPES.include?(content_type) ||
      content_type == WeddingAssets::VideoProcessor::OUTPUT_CONTENT_TYPE
  end

  def image?
    !video?
  end

  private

  def delete_remote_objects
    [object_key, thumbnail_object_key].each do |key|
      DisposableCamera::StorageClient.delete!(object_key: key)
    rescue Aws::S3::Errors::ServiceError, Seahorse::Client::NetworkingError => e
      Rails.logger.error("Wedding asset remote delete failed for key=#{key}: #{e.class}: #{e.message}")
    end
  end
end

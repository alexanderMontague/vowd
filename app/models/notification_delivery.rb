class NotificationDelivery < ApplicationRecord
  CHANNELS = %w[email].freeze
  STATUSES = %w[queued sent failed].freeze

  belongs_to :guest

  validates :wedding_id, presence: true
  validates :reminder_key, presence: true
  validates :scheduled_for, presence: true
  validates :channel, inclusion: { in: CHANNELS }
  validates :status, inclusion: { in: STATUSES }
  validates :guest_id, uniqueness: { scope: %i[wedding_id reminder_key channel] }

  scope :sent, -> { where(status: "sent") }
  scope :failed, -> { where(status: "failed") }
  scope :queued, -> { where(status: "queued") }

  def mark_sent!
    update!(status: "sent", sent_at: Time.current, error_message: nil)
  end

  def mark_failed!(message)
    update!(status: "failed", error_message: message.to_s.truncate(500))
  end
end

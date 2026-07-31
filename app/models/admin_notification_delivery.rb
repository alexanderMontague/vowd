class AdminNotificationDelivery < ApplicationRecord
  KINDS = %w[
    welcome
    trial_expiring_3d
    trial_expiring_1d
    schedule_locking
    wedding_congrats
  ].freeze

  STATUSES = %w[queued sent failed].freeze

  belongs_to :wedding, foreign_key: :wedding_id, primary_key: :id, inverse_of: false

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :kind, uniqueness: { scope: :wedding_id }

  def mark_sent!
    update!(status: "sent", sent_at: Time.current, error_message: nil)
  end

  def mark_failed!(message)
    update!(status: "failed", error_message: message.to_s.truncate(1000))
  end
end

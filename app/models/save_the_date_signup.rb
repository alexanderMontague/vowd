class SaveTheDateSignup < ApplicationRecord
  include WeddingScoped

  belongs_to :guest, optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates_same_wedding :guest

  normalizes :email, with: ->(email) { email.strip.downcase }

  scope :matched, -> { where.not(guest_id: nil) }
  scope :unmatched, -> { where(guest_id: nil) }
  scope :recent_first, -> { order(created_at: :desc) }

  def matched?
    guest_id.present?
  end

  def display_name
    name.presence || email
  end
end

class Guest < ApplicationRecord
  include WeddingScoped

  belongs_to :household
  has_one :rsvp, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :notification_deliveries, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :invite_code, presence: true, uniqueness: { scope: :wedding_id }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates_same_wedding :household

  before_validation :set_wedding_id_from_household, on: :create
  before_validation :generate_invite_code, on: :create
  after_create :create_default_rsvp

  scope :with_email, -> { where.not(email: nil).where.not(email: "") }
  scope :rsvp_accepted, -> { joins(:rsvp).where(rsvps: { status: "accepted" }) }
  scope :rsvp_declined, -> { joins(:rsvp).where(rsvps: { status: "declined" }) }
  scope :rsvp_pending, -> { joins(:rsvp).where(rsvps: { status: "pending" }) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def rsvp_status
    rsvp&.status || "pending"
  end

  def has_responded?
    rsvp&.status != "pending"
  end

  private

  def set_wedding_id_from_household
    self.wedding_id = household.wedding_id if household.present? && wedding_id.blank?
  end

  def generate_invite_code
    return if invite_code.present?

    loop do
      self.invite_code = SecureRandom.alphanumeric(10).upcase
      break unless Guest.exists?(wedding_id: wedding_id, invite_code: invite_code)
    end
  end

  def create_default_rsvp
    create_rsvp!(status: "pending") if rsvp.blank?
  end
end

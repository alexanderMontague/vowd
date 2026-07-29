class PartyPoll < ApplicationRecord
  include UuidPrimaryKey
  include WeddingScoped

  STATUSES = %w[open closed].freeze

  belongs_to :party_board, inverse_of: :polls
  has_many :options, class_name: "PartyPollOption", dependent: :destroy, inverse_of: :party_poll
  has_many :votes, class_name: "PartyPollVote", dependent: :destroy, inverse_of: :party_poll

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates_same_wedding :party_board

  before_validation :copy_wedding_id_from_board, on: :create

  scope :ordered, -> { order(:position, :created_at) }
  scope :open, -> { where(status: "open") }

  def open?
    status == "open"
  end

  def closed?
    status == "closed"
  end

  private

  def copy_wedding_id_from_board
    self.wedding_id ||= party_board&.wedding_id
  end
end

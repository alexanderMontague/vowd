class PartyMember < ApplicationRecord
  include UuidPrimaryKey
  include WeddingScoped

  SOURCES = %w[wedding_party custom].freeze

  belongs_to :party_board, inverse_of: :members
  has_many :votes, class_name: "PartyPollVote", dependent: :destroy, inverse_of: :party_member

  validates :name, presence: true
  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :wedding_party_key, uniqueness: { scope: :party_board_id }, allow_nil: true
  validates_same_wedding :party_board

  before_validation :copy_wedding_id_from_board, on: :create

  scope :ordered, -> { order(:position, :name, :created_at) }

  private

  def copy_wedding_id_from_board
    self.wedding_id ||= party_board&.wedding_id
  end
end

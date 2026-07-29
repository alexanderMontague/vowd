class PartyIdea < ApplicationRecord
  include UuidPrimaryKey
  include WeddingScoped

  belongs_to :party_board, inverse_of: :ideas

  validates :title, presence: true
  validates_same_wedding :party_board

  before_validation :copy_wedding_id_from_board, on: :create

  scope :ordered, -> { order(:position, :created_at) }

  private

  def copy_wedding_id_from_board
    self.wedding_id ||= party_board&.wedding_id
  end
end

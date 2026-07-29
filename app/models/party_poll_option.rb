class PartyPollOption < ApplicationRecord
  include UuidPrimaryKey
  include WeddingScoped

  belongs_to :party_poll, inverse_of: :options
  has_many :votes, class_name: "PartyPollVote", dependent: :destroy, inverse_of: :party_poll_option

  validates :title, presence: true
  validates_same_wedding :party_poll

  before_validation :copy_wedding_id_from_poll, on: :create

  scope :ordered, -> { order(:position, :created_at) }

  def vote_count
    votes.count
  end

  private

  def copy_wedding_id_from_poll
    self.wedding_id ||= party_poll&.wedding_id
  end
end

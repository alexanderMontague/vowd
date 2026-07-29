class PartyPollVote < ApplicationRecord
  include UuidPrimaryKey
  include WeddingScoped

  belongs_to :party_poll, inverse_of: :votes
  belongs_to :party_poll_option, inverse_of: :votes
  belongs_to :party_member, inverse_of: :votes

  validates :party_member_id, uniqueness: { scope: :party_poll_id, message: "has already voted on this poll" }
  validate :option_belongs_to_poll
  validate :member_belongs_to_board
  validates_same_wedding :party_poll, :party_poll_option, :party_member

  before_validation :copy_wedding_id_from_poll, on: :create

  private

  def copy_wedding_id_from_poll
    self.wedding_id ||= party_poll&.wedding_id
  end

  def option_belongs_to_poll
    return if party_poll.blank? || party_poll_option.blank?
    return if party_poll_option.party_poll_id == party_poll_id

    errors.add(:party_poll_option, "must belong to this poll")
  end

  def member_belongs_to_board
    return if party_poll.blank? || party_member.blank?
    return if party_member.party_board_id == party_poll.party_board_id

    errors.add(:party_member, "must belong to this party board")
  end
end

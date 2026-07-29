class PartyBoard < ApplicationRecord
  include UuidPrimaryKey
  include WeddingScoped

  KINDS = %w[bachelor bachelorette].freeze
  STATUSES = %w[active archived].freeze
  DEFAULT_TITLES = {
    "bachelor" => "Bachelor party",
    "bachelorette" => "Bachelorette party"
  }.freeze
  WEDDING_PARTY_GROUPS = {
    "bachelor" => "groomsmen",
    "bachelorette" => "bridesmaids"
  }.freeze

  has_many :members, class_name: "PartyMember", dependent: :destroy, inverse_of: :party_board
  has_many :ideas, class_name: "PartyIdea", dependent: :destroy, inverse_of: :party_board
  has_many :itinerary_items, class_name: "PartyItineraryItem", dependent: :destroy, inverse_of: :party_board
  has_many :polls, class_name: "PartyPoll", dependent: :destroy, inverse_of: :party_board

  validates :kind, presence: true, inclusion: { in: KINDS }, uniqueness: { scope: :wedding_id }
  validates :title, presence: true
  validates :share_token, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  before_validation :assign_defaults, on: :create

  scope :ordered, -> { order(Arel.sql("CASE kind WHEN 'bachelor' THEN 0 ELSE 1 END"), :created_at) }

  def self.ensure_for!(wedding)
    KINDS.map do |kind|
      find_or_create_by!(wedding_id: wedding.id, kind: kind) do |board|
        board.title = DEFAULT_TITLES.fetch(kind)
      end
    end
  end

  def self.find_by_share_token!(token)
    find_by!(share_token: token)
  end

  def wedding_party_group
    WEDDING_PARTY_GROUPS.fetch(kind)
  end

  def label
    DEFAULT_TITLES.fetch(kind)
  end

  def share_path
    "/party/#{share_token}"
  end

  def regenerate_share_token!
    update!(share_token: self.class.generate_share_token)
  end

  def open_polls
    polls.open
  end

  def self.generate_share_token
    loop do
      token = SecureRandom.urlsafe_base64(16)
      break token unless exists?(share_token: token)
    end
  end

  private

  def assign_defaults
    self.title = DEFAULT_TITLES.fetch(kind.to_s) if title.blank? && kind.present?
    self.share_token = self.class.generate_share_token if share_token.blank?
    self.status = "active" if status.blank?
  end
end

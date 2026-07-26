class Household < ApplicationRecord
  include WeddingScoped

  has_many :guests, dependent: :destroy
  accepts_nested_attributes_for :guests, allow_destroy: true, reject_if: :all_blank_guest?

  validates :name, presence: false

  before_save :assign_wedding_id_to_guests

  def primary_guest
    guests.order(:created_at).first
  end

  def guest_names
    guests.map(&:full_name).join(", ")
  end

  def display_name
    name.presence || guest_names.presence || "Unnamed Household"
  end

  def rsvpd?
    guests.all?(&:has_responded?)
  end

  private

  def assign_wedding_id_to_guests
    guests.each do |guest|
      guest.wedding_id = wedding_id if guest.wedding_id.blank?
    end
  end

  def all_blank_guest?(attributes)
    attributes["first_name"].blank? && attributes["last_name"].blank?
  end
end

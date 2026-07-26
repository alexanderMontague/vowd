module WeddingScoped
  extend ActiveSupport::Concern

  included do
    validates :wedding_id, presence: true
  end

  class_methods do
    # Rejects records whose association points at a different tenant. Without this,
    # wedding-scoped uniqueness and wedding-scoped lookups can be bypassed by
    # reaching a foreign record through an association that is not itself scoped.
    def validates_same_wedding(*association_names)
      validate do
        association_names.each do |association_name|
          associated = public_send(association_name)
          next if associated.nil? || associated.wedding_id == wedding_id

          errors.add(association_name, "must belong to the same wedding")
        end
      end
    end
  end

  def wedding
    Wedding.find(wedding_id)
  end
end

# Form sections of the Wedding editor. Events lives beside these as its own CRUD.
class WebsiteSections
  Section = Data.define(:key, :label)

  DEFINITIONS = [
    Section.new(key: "essentials", label: "Essentials"),
    Section.new(key: "meals", label: "Meal options"),
    Section.new(key: "domain", label: "Custom domain"),
    Section.new(key: "notifications", label: "Notifications")
  ].freeze

  DEFAULT_KEY = "essentials".freeze

  class << self
    def definitions
      DEFINITIONS
    end

    def find(key)
      DEFINITIONS.find { |section| section.key == key.to_s }
    end

    def keys
      DEFINITIONS.map(&:key)
    end

    def default
      find(DEFAULT_KEY)
    end

    def constraint
      Regexp.union(keys)
    end
  end
end

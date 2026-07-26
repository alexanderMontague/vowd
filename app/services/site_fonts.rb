# Curated Google Font pairings a wedding can choose from. Pairings rather than free
# text so every combination has been checked for weight availability and contrast
# between the display and body faces.
class SiteFonts
  SERIF_FALLBACK = "Georgia, Cambria, 'Times New Roman', serif".freeze
  SANS_FALLBACK = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif".freeze

  # `google_families` holds css2 `family` query fragments, already URL-safe.
  Pairing = Data.define(:key, :label, :description, :display_face, :body_face, :google_families) do
    def display_family
      "'#{display_face}', #{SERIF_FALLBACK}"
    end

    def body_family
      "'#{body_face}', #{SANS_FALLBACK}"
    end

    def google_href
      query = google_families.map { |family| "family=#{family}" }.join("&")
      "https://fonts.googleapis.com/css2?#{query}&display=swap"
    end
  end

  DEFINITIONS = [
    Pairing.new(
      key: "classic",
      label: "Cormorant Garamond & Montserrat",
      description: "Airy high-contrast serif over a quiet geometric sans. The house pairing.",
      display_face: "Cormorant Garamond",
      body_face: "Montserrat",
      google_families: [
        "Cormorant+Garamond:ital,wght@0,300;0,400;0,500;0,600;1,300;1,400",
        "Montserrat:wght@200;300;400;500"
      ]
    ),
    Pairing.new(
      key: "romantic",
      label: "Playfair Display & Lato",
      description: "Rounder, warmer serif with a friendly humanist sans underneath.",
      display_face: "Playfair Display",
      body_face: "Lato",
      google_families: [
        "Playfair+Display:ital,wght@0,400;0,500;0,600;1,400",
        "Lato:wght@300;400;700"
      ]
    ),
    Pairing.new(
      key: "editorial",
      label: "Bodoni Moda & Inter",
      description: "Razor-sharp didone headlines against a neutral screen sans.",
      display_face: "Bodoni Moda",
      body_face: "Inter",
      google_families: [
        "Bodoni+Moda:ital,opsz,wght@0,6..96,400;0,6..96,500;1,6..96,400",
        "Inter:wght@300;400;500;600"
      ]
    ),
    Pairing.new(
      key: "refined",
      label: "EB Garamond & Work Sans",
      description: "Old-style serif with generous body copy. Reads well at length.",
      display_face: "EB Garamond",
      body_face: "Work Sans",
      google_families: [
        "EB+Garamond:ital,wght@0,400;0,500;0,600;1,400",
        "Work+Sans:wght@300;400;500"
      ]
    ),
    Pairing.new(
      key: "modern",
      label: "Marcellus & Karla",
      description: "Roman capitals with a slightly quirky grotesque for detail text.",
      display_face: "Marcellus",
      body_face: "Karla",
      google_families: [
        "Marcellus",
        "Karla:wght@300;400;500"
      ]
    ),
    Pairing.new(
      key: "airy",
      label: "Italiana & Nunito Sans",
      description: "Very light engraved capitals over a soft rounded sans.",
      display_face: "Italiana",
      body_face: "Nunito Sans",
      google_families: [
        "Italiana",
        "Nunito+Sans:wght@200;300;400;600"
      ]
    )
  ].freeze

  DEFAULT_KEY = "classic".freeze

  class << self
    def definitions
      DEFINITIONS
    end

    def find(key)
      DEFINITIONS.find { |pairing| pairing.key == key.to_s }
    end

    def fetch(key, fallback: DEFAULT_KEY)
      find(key) || find(fallback) || DEFINITIONS.first
    end

    def keys
      DEFINITIONS.map(&:key)
    end

    def options
      DEFINITIONS.map { |pairing| [pairing.label, pairing.key] }
    end
  end
end

# Colour arithmetic for theme palettes. Couples pick arbitrary hex values, so
# anything painted on top of those values has to be chosen rather than assumed.
class ThemeColor
  HEX_FORMAT = /\A#(?:\h{3}|\h{6})\z/

  LIGHT_FOREGROUND = "#FFFFFF".freeze
  DARK_FOREGROUND = "#1C1917".freeze

  class << self
    def valid?(value)
      value.to_s.strip.match?(HEX_FORMAT)
    end

    # Returns a canonical 6-digit uppercase hex, or the fallback when the input is
    # not a colour we can render.
    def normalize(value, fallback:)
      candidate = value.to_s.strip
      return fallback unless valid?(candidate)

      expand(candidate).upcase
    end

    # The foreground colour that stays readable on top of the given background,
    # picked by comparing actual contrast ratios rather than guessing at a lightness
    # cutoff. Mid-tone golds land on dark text, which is what a designer would do.
    def legible_on(background)
      light = contrast_ratio(LIGHT_FOREGROUND, background)
      dark = contrast_ratio(DARK_FOREGROUND, background)

      dark > light ? DARK_FOREGROUND : LIGHT_FOREGROUND
    end

    # WCAG contrast ratio between two colours, from 1 (identical) to 21 (black/white).
    def contrast_ratio(foreground, background)
      lighter, darker = [luminance(foreground), luminance(background)].minmax.reverse

      (lighter + 0.05) / (darker + 0.05)
    end

    # WCAG relative luminance (0 = black, 1 = white).
    def luminance(hex)
      return 0.0 unless valid?(hex)

      r, g, b = channels(hex).map { |channel| linearize(channel / 255.0) }
      (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
    end

    private

    def expand(hex)
      digits = hex.delete_prefix("#")
      return hex if digits.length == 6

      "##{digits.chars.map { |digit| digit * 2 }.join}"
    end

    def channels(hex)
      expand(hex).delete_prefix("#").scan(/\h{2}/).map { |pair| pair.to_i(16) }
    end

    def linearize(channel)
      channel <= 0.03928 ? channel / 12.92 : ((channel + 0.055) / 1.055)**2.4
    end
  end
end

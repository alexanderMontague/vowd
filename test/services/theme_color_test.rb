require "test_helper"

class ThemeColorTest < ActiveSupport::TestCase
  test "normalises shorthand and casing to a canonical six digit hex" do
    assert_equal "#AABBCC", ThemeColor.normalize("#abc", fallback: "#000000")
    assert_equal "#C89B7B", ThemeColor.normalize("  #c89b7b  ", fallback: "#000000")
  end

  test "falls back when the value is not a colour" do
    ["", nil, "rgb(1,2,3)", "#12345", "chartreuse"].each do |value|
      assert_equal "#000000", ThemeColor.normalize(value, fallback: "#000000"),
                   "expected #{value.inspect} to be rejected"
    end
  end

  test "picks the foreground with the higher contrast ratio" do
    assert_equal ThemeColor::LIGHT_FOREGROUND, ThemeColor.legible_on("#292524")
    assert_equal ThemeColor::DARK_FOREGROUND, ThemeColor.legible_on("#FAFAF9")
  end

  test "mid tone golds keep dark text, which is the higher contrast choice" do
    gold = "#C89B7B"

    assert_equal ThemeColor::DARK_FOREGROUND, ThemeColor.legible_on(gold)
    assert_operator ThemeColor.contrast_ratio(ThemeColor::DARK_FOREGROUND, gold),
                    :>,
                    ThemeColor.contrast_ratio(ThemeColor::LIGHT_FOREGROUND, gold)
  end

  test "contrast ratio is symmetric and bounded by black on white" do
    assert_in_delta 21.0, ThemeColor.contrast_ratio("#000000", "#FFFFFF"), 0.05
    assert_in_delta ThemeColor.contrast_ratio("#000000", "#FFFFFF"),
                    ThemeColor.contrast_ratio("#FFFFFF", "#000000"),
                    0.001
    assert_in_delta 1.0, ThemeColor.contrast_ratio("#336699", "#336699"), 0.001
  end
end

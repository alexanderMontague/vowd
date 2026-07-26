require "test_helper"

class WeddingHelperTest < ActionView::TestCase
  tests WeddingHelper

  test "reads a monogram from the two names in a couple's title" do
    assert_equal "AJ", monogram_for("Amelia & Julian")
    assert_equal "AJ", monogram_for("Amelia and Julian")
    assert_equal "AJ", monogram_for("Amelia + Julian")
  end

  test "does not mistake an embedded 'and' for a separator" do
    assert_equal "AB", monogram_for("Alexander & Brandon")
  end

  test "falls back to the leading words when the title does not name a couple" do
    assert_equal "TM", monogram_for("The Montague Wedding")
    assert_equal "H", monogram_for("Hitched")
  end

  test "is blank rather than broken without a title" do
    assert_equal "", monogram_for(nil)
    assert_equal "", wedding_monogram(nil)
  end

  private

  def monogram_for(title)
    wedding_monogram(Wedding.new(title: title))
  end
end

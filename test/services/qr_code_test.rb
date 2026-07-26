require "test_helper"

class QrCodeTest < ActiveSupport::TestCase
  URL = "https://example.test/dispo".freeze

  test "svg keeps a four module quiet zone at any module size" do
    [3, 8, 20].each do |module_size|
      svg = QrCode.new(URL).svg(module_size: module_size)
      expected_offset = module_size * QrCode::QUIET_ZONE_MODULES

      # The first module rect sits exactly one quiet zone in from the origin.
      assert_match(/<rect width="#{module_size}" height="#{module_size}" x="#{expected_offset}"/, svg,
                   "module_size #{module_size} should inset modules by #{expected_offset}")
    end
  end

  test "svg is scalable and carries a paper coloured background" do
    svg = QrCode.new(URL).svg

    assert_includes svg, "viewBox"
    assert_includes svg, "fill=\"##{QrCode::PAPER}\""
    assert_includes svg, "fill=\"##{QrCode::INK}\""
  end

  test "png renders at the requested pixel size" do
    png = QrCode.new(URL).png(size: 600)

    assert_equal 600, ChunkyPNG::Image.from_blob(png).width
  end

  test "custom ink and paper are honoured for artifacts with their own palette" do
    svg = QrCode.new(URL, ink: "78716c", paper: "ffffff").svg

    assert_includes svg, 'fill="#78716c"'
    assert_includes svg, 'fill="#ffffff"'
  end
end

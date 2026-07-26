require "test_helper"

module DisposableCamera
  class SignTest < ActiveSupport::TestCase
    test "the encoded url points at this wedding's own dispo page" do
      sign = Sign.new(wedding: create_wedding(id: "sign-wedding"))

      assert_equal "http://sign-wedding.example.test:3003/dispo", sign.url
    end

    test "each wedding gets a distinct code target" do
      first = Sign.new(wedding: create_wedding(id: "first-wedding"))
      second = Sign.new(wedding: create_wedding(id: "second-wedding"))

      assert_not_equal first.url, second.url
    end

    test "the encoded url honours a custom domain" do
      wedding = create_wedding(id: "branded-wedding", custom_domain: "photos.example.com")

      assert_equal "http://photos.example.com:3003/dispo", Sign.new(wedding: wedding).url
    end

    test "display_url drops the scheme so it is easy to read on a printed sign" do
      sign = Sign.new(wedding: create_wedding(id: "readable-wedding"))

      assert_equal "readable-wedding.example.test:3003/dispo", sign.display_url
    end

    test "svg renders a scalable standalone document" do
      svg = Sign.new(wedding: create_wedding).svg

      assert_includes svg, "<svg"
      assert_includes svg, "viewBox"
    end

    test "png renders binary image data at print resolution" do
      png = Sign.new(wedding: create_wedding).png

      assert_equal [137, 80, 78, 71].pack("C*"), png.byteslice(0, 4)
      assert_equal 2000, ChunkyPNG::Image.from_blob(png).width
    end

    test "filenames are namespaced per wedding so downloads do not collide" do
      sign = Sign.new(wedding: create_wedding(id: "filename-wedding"))

      assert_equal "dispo-qr-filename-wedding.png", sign.filename(extension: "png")
      assert_equal "dispo-qr-filename-wedding.svg", sign.filename(extension: "svg")
    end
  end
end

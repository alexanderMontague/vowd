require "test_helper"

class DisposablePhotoTest < ActiveSupport::TestCase
  test "download_filename combines prefix, capture timestamp and extension" do
    photo = DisposablePhoto.new(
      object_key: "production/w/photos/abc.png",
      captured_at: Time.utc(2026, 7, 10, 23, 15, 0)
    )

    assert_equal "montague-20260710-231500.png", photo.download_filename(prefix: "montague")
  end

  test "download_filename defaults the extension when the object key has none" do
    photo = DisposablePhoto.new(
      object_key: "production/w/photos/abc",
      captured_at: Time.utc(2026, 7, 10, 23, 15, 0)
    )

    assert_equal "montague-20260710-231500.jpg", photo.download_filename(prefix: "montague")
  end
end

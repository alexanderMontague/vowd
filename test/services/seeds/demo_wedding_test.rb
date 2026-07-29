require "test_helper"

module Seeds
  class DemoWeddingTest < ActiveSupport::TestCase
    test "creates demo wedding admin guests and assets idempotently" do
      first = DemoWedding.call
      second = DemoWedding.call

      assert_equal DemoWedding::SLUG, first.id
      assert_equal first.id, second.id
      assert_equal "Britt & Alex", first.title
      assert AdminUser.exists?(email: DemoWedding::ADMIN_EMAIL, wedding_id: DemoWedding::SLUG)
      assert first.guests.exists?
      assert first.wedding_assets.exists?
      assert_equal 1, Wedding.where(id: DemoWedding::SLUG).count
      assert_equal 1, AdminUser.where(email: DemoWedding::ADMIN_EMAIL).count
    end
  end
end

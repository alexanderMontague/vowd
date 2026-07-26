require "test_helper"

class GuestTest < ActiveSupport::TestCase
  setup do
    @wedding_a = create_wedding
    @wedding_b = create_wedding
    @household_a = Household.create!(wedding_id: @wedding_a.id, name: "Household A")
    @household_b = Household.create!(wedding_id: @wedding_b.id, name: "Household B")
  end

  test "invite codes are unique within a wedding" do
    existing = create_guest(@household_a)
    duplicate = build_guest(@household_a, invite_code: existing.invite_code)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:invite_code], "has already been taken"
  end

  test "the same invite code may be reused across weddings" do
    existing = create_guest(@household_a)
    other_wedding_guest = build_guest(@household_b, invite_code: existing.invite_code)

    assert other_wedding_guest.valid?
    assert other_wedding_guest.save
    assert_equal existing.invite_code, other_wedding_guest.reload.invite_code
  end

  test "generated invite codes only avoid collisions within the same wedding" do
    existing = create_guest(@household_a)

    SecureRandom.stub(:alphanumeric, existing.invite_code.downcase) do
      assert_equal existing.invite_code, create_guest(@household_b).invite_code
    end
  end

  test "generated invite codes retry until free within the same wedding" do
    existing = create_guest(@household_a)
    codes = [existing.invite_code.downcase, "freshcode1"]

    SecureRandom.stub(:alphanumeric, ->(_length) { codes.shift }) do
      assert_equal "FRESHCODE1", create_guest(@household_a).invite_code
    end
  end

  test "a guest cannot be created in another wedding's household" do
    guest = build_guest(@household_b, wedding_id: @wedding_a.id)

    assert_not guest.valid?
    assert_includes guest.errors[:household], "must belong to the same wedding"
  end

  test "a guest cannot be moved into another wedding's household" do
    guest = create_guest(@household_a)

    assert_not guest.update(household: @household_b)
    assert_includes guest.errors[:household], "must belong to the same wedding"
    assert_equal @household_a.id, guest.reload.household_id
  end

  test "wedding_id is required" do
    guest = Guest.new(first_name: "Ada", last_name: "Lovelace")

    assert_not guest.valid?
    assert_includes guest.errors[:wedding_id], "can't be blank"
  end

  private

  def build_guest(household, attrs = {})
    Guest.new({ household: household, first_name: "Ada", last_name: "Lovelace" }.merge(attrs))
  end

  def create_guest(household, attrs = {})
    build_guest(household, attrs).tap(&:save!)
  end
end

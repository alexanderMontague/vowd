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

  test "destroy nullifies matched save the date signups and keeps the lead" do
    guest = create_guest(@household_a, email: "ada@example.com")
    signup = SaveTheDateSignup.create!(
      wedding_id: @wedding_a.id,
      email: "ada@example.com",
      guest: guest,
      matched_at: Time.current
    )

    assert_difference("Guest.count", -1) do
      assert_no_difference("SaveTheDateSignup.count") do
        guest.destroy!
      end
    end

    signup.reload
    assert_nil signup.guest_id
    assert_nil signup.matched_at
  end

  test "destroy removes rsvps invitations and notification deliveries" do
    guest = create_guest(@household_a, email: "ada@example.com")
    Invitation.create!(guest: guest, status: "sent", sent_at: Time.current)
    NotificationDelivery.create!(
      guest: guest,
      wedding_id: @wedding_a.id,
      reminder_key: "week_before",
      channel: "email",
      scheduled_for: Date.current,
      status: "queued"
    )

    assert_difference("RSVP.count", -1) do
      assert_difference("Invitation.count", -1) do
        assert_difference("NotificationDelivery.count", -1) do
          guest.destroy!
        end
      end
    end
  end

  test "destroy nullifies disposable photo attribution" do
    guest = create_guest(@household_a)
    photo = DisposablePhoto.create!(
      wedding_id: @wedding_a.id,
      guest: guest,
      object_key: "test/#{SecureRandom.hex(8)}.jpg",
      content_type: "image/jpeg",
      byte_size: 1234,
      flash_enabled: false,
      captured_at: Time.current
    )

    DisposableCamera::StorageClient.stub(:delete!, true) do
      assert_no_difference("DisposablePhoto.count") do
        guest.destroy!
      end
    end

    assert_nil photo.reload.guest_id
  end

  private

  def build_guest(household, attrs = {})
    Guest.new({ household: household, first_name: "Ada", last_name: "Lovelace" }.merge(attrs))
  end

  def create_guest(household, attrs = {})
    build_guest(household, attrs).tap(&:save!)
  end
end

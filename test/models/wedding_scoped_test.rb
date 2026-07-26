require "test_helper"

class WeddingScopedTest < ActiveSupport::TestCase
  setup do
    @wedding = create_wedding
    @other_wedding = create_wedding
    @other_guest = Guest.create!(
      household: Household.create!(wedding_id: @other_wedding.id, name: "Other Household"),
      first_name: "Grace",
      last_name: "Hopper",
      email: "grace@example.com"
    )
  end

  test "a save the date signup cannot be matched to another wedding's guest" do
    signup = SaveTheDateSignup.new(
      wedding_id: @wedding.id,
      email: "guest@example.com",
      guest: @other_guest
    )

    assert_not signup.valid?
    assert_includes signup.errors[:guest], "must belong to the same wedding"
  end

  test "a disposable photo cannot be attributed to another wedding's guest" do
    photo = DisposablePhoto.new(
      wedding_id: @wedding.id,
      guest: @other_guest,
      object_key: "test/#{@wedding.id}/photos/one.jpg",
      content_type: "image/jpeg",
      byte_size: 1_024,
      captured_at: Time.current
    )

    assert_not photo.valid?
    assert_includes photo.errors[:guest], "must belong to the same wedding"
  end

  test "a notification delivery cannot target another wedding's guest" do
    delivery = NotificationDelivery.new(
      wedding_id: @wedding.id,
      guest: @other_guest,
      reminder_key: "day_before",
      channel: "email",
      scheduled_for: Date.current
    )

    assert_not delivery.valid?
    assert_includes delivery.errors[:guest], "must belong to the same wedding"
  end

  test "records that reference a guest from their own wedding are valid" do
    own_guest = Guest.create!(
      household: Household.create!(wedding_id: @wedding.id, name: "Own Household"),
      first_name: "Ada",
      last_name: "Lovelace",
      email: "ada@example.com"
    )

    signup = SaveTheDateSignup.new(wedding_id: @wedding.id, email: "ada@example.com", guest: own_guest)

    assert signup.valid?, signup.errors.full_messages.to_sentence
  end

  test "wedding_id is required on every wedding scoped record" do
    [Household.new, Event.new(name: "Ceremony"), SaveTheDateSignup.new(email: "a@example.com")].each do |record|
      assert_not record.valid?, "#{record.class} should require a wedding_id"
      assert_includes record.errors[:wedding_id], "can't be blank"
    end
  end
end

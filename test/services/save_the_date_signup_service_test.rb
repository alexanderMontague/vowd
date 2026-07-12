require "test_helper"

class SaveTheDateSignupServiceTest < ActiveSupport::TestCase
  setup do
    @wedding = Wedding.current
    @household = Household.create!(wedding_id: @wedding.id, name: "Match Household")
  end

  test "creates a signup and normalizes email" do
    result = SaveTheDateSignupService.submit!(
      wedding: @wedding,
      signup_params: { name: "Jamie", email: "  JAMIE@Example.com ", phone_number: "555-1234" }
    )

    assert result[:success]
    signup = result[:signup]
    assert_equal "jamie@example.com", signup.email
    assert_equal @wedding.id, signup.wedding_id
    assert_not signup.matched?
  end

  test "auto-matches to an existing guest with the same email" do
    guest = Guest.create!(
      wedding_id: @wedding.id, household: @household,
      first_name: "Robin", last_name: "Doe", email: "robin@example.com"
    )

    result = SaveTheDateSignupService.submit!(
      wedding: @wedding,
      signup_params: { email: "ROBIN@example.com", phone_number: "555-9999" }
    )

    signup = result[:signup]
    assert signup.matched?
    assert_equal guest.id, signup.guest_id
    assert_not_nil signup.matched_at
    assert_equal "555-9999", guest.reload.phone_number
  end

  test "does not overwrite an existing guest phone number" do
    guest = Guest.create!(
      wedding_id: @wedding.id, household: @household,
      first_name: "Sam", last_name: "Doe", email: "sam@example.com", phone_number: "111-1111"
    )

    SaveTheDateSignupService.submit!(
      wedding: @wedding,
      signup_params: { email: "sam@example.com", phone_number: "222-2222" }
    )

    assert_equal "111-1111", guest.reload.phone_number
  end

  test "returns error for invalid email without creating a record" do
    assert_no_difference("SaveTheDateSignup.count") do
      result = SaveTheDateSignupService.submit!(
        wedding: @wedding,
        signup_params: { email: "not-an-email" }
      )
      assert_not result[:success]
      assert result[:error].present?
    end
  end
end

require "test_helper"

module Admin
  class HouseholdsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding
      @admin = create_admin_for(@wedding)
      sign_in_admin(@admin)
    end

    test "index redirects to guests" do
      get admin_households_path

      assert_redirected_to admin_guests_path
    end

    test "new renders the household form with a blank guest" do
      get new_admin_household_path

      assert_response :success
      assert_select "form[action=?]", admin_households_path
      assert_select "input[name='household[guests_attributes][0][first_name]']"
    end

    test "create saves a household with nested guests" do
      assert_difference("Household.count", 1) do
        assert_difference("Guest.count", 2) do
          post admin_households_path, params: {
            household: {
              name: "Capulet",
              guests_attributes: {
                "0" => { first_name: "Juliet", last_name: "Capulet", email: "juliet@example.com" },
                "1" => { first_name: "Tybalt", last_name: "Capulet", email: "tybalt@example.com" }
              }
            }
          }
        end
      end

      assert_redirected_to admin_guests_path
      household = Household.order(:id).last
      assert_equal "Capulet", household.name
      assert_equal @wedding.id, household.wedding_id
      assert_equal 2, household.guests.count
      assert household.guests.all? { |guest| guest.rsvp.present? }
    end

    test "create rejects blank nested guests and still saves named ones" do
      assert_difference("Guest.count", 1) do
        post admin_households_path, params: {
          household: {
            name: "Solo",
            guests_attributes: {
              "0" => { first_name: "Only", last_name: "Guest", email: "only@example.com" },
              "1" => { first_name: "", last_name: "", email: "" }
            }
          }
        }
      end

      assert_redirected_to admin_guests_path
    end

    test "show redirects to edit" do
      household = Household.create!(wedding_id: @wedding.id, name: "Edit Me")

      get admin_household_path(household)

      assert_redirected_to edit_admin_household_path(household)
    end

    test "edit renders existing guests" do
      household, = create_household_with_guest("Jordan", "Lee")

      get edit_admin_household_path(household)

      assert_response :success
      assert_select "input[value=?]", "Jordan"
      assert_select "input[value=?]", "Lee"
    end

    test "update changes household and guest details" do
      household, guest = create_household_with_guest("Jordan", "Lee")

      patch admin_household_path(household), params: {
        household: {
          name: "Lee Family",
          guests_attributes: {
            "0" => { id: guest.id, first_name: "Jordyn", last_name: "Lee", email: "jordyn@example.com" }
          }
        }
      }

      assert_redirected_to admin_guests_path
      assert_equal "Lee Family", household.reload.name
      assert_equal "Jordyn", guest.reload.first_name
    end

    test "update can remove a nested guest even when matched to a signup" do
      household, guest = create_household_with_guest("Jordan", "Lee", email: "jordan@example.com")
      signup = SaveTheDateSignup.create!(
        wedding_id: @wedding.id,
        email: "jordan@example.com",
        guest: guest,
        matched_at: Time.current
      )

      assert_difference("Guest.count", -1) do
        assert_no_difference("SaveTheDateSignup.count") do
          patch admin_household_path(household), params: {
            household: {
              name: household.name,
              guests_attributes: {
                "0" => { id: guest.id, first_name: "Jordan", last_name: "Lee", _destroy: "1" }
              }
            }
          }
        end
      end

      assert_redirected_to admin_guests_path
      signup.reload
      assert_nil signup.guest_id
      assert_nil signup.matched_at
    end

    test "destroy removes household and guests" do
      household, = create_household_with_guest("Jordan", "Lee")

      assert_difference("Household.count", -1) do
        assert_difference("Guest.count", -1) do
          assert_difference("RSVP.count", -1) do
            delete admin_household_path(household)
          end
        end
      end

      assert_redirected_to admin_guests_path
    end

    test "destroy unlinks matched save the date signups for household guests" do
      household, guest = create_household_with_guest("Jordan", "Lee", email: "jordan@example.com")
      signup = SaveTheDateSignup.create!(
        wedding_id: @wedding.id,
        email: "jordan@example.com",
        guest: guest,
        matched_at: Time.current
      )

      assert_difference("Household.count", -1) do
        assert_no_difference("SaveTheDateSignup.count") do
          delete admin_household_path(household)
        end
      end

      signup.reload
      assert_nil signup.guest_id
      assert_nil signup.matched_at
    end

    test "destroy does not allow deleting another wedding's household" do
      other_wedding = create_wedding
      other = Household.create!(wedding_id: other_wedding.id, name: "Foreign")

      assert_no_difference("Household.count") do
        delete admin_household_path(other)
      end

      assert_response :not_found
    end

    private

    def create_household_with_guest(first_name, last_name, email: nil)
      household = Household.create!(wedding_id: @wedding.id, name: "#{last_name} Household")
      guest = Guest.create!(
        wedding_id: @wedding.id,
        household: household,
        first_name: first_name,
        last_name: last_name,
        email: email || "#{first_name.downcase}@example.com"
      )
      [household, guest]
    end
  end
end

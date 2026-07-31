require "test_helper"

module Admin
  class WebsiteControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding(title: "Original Title")
      @admin = create_admin_for(@wedding)
      sign_in_admin(@admin)
    end

    test "website root redirects to essentials section" do
      get admin_website_path

      assert_redirected_to admin_website_section_path(section: "essentials")
    end

    test "essentials section renders wedding logistics editor" do
      get admin_website_section_path(section: "essentials")

      assert_response :success
      assert_includes response.body, "Original Title"
      assert_includes response.body, "Essentials"
      assert_includes response.body, "Changes save automatically"
      assert_includes response.body, "form-autosave"
      assert_not_includes response.body, "Hero tagline"
      assert_not_includes response.body, "gallery_images_json"
    end

    test "unconfigured wedding shows focused setup checklist" do
      @wedding.update!(partner1: nil, partner2: nil, date: nil)

      get admin_website_path

      assert_response :success
      assert_includes response.body, "Set up your wedding"
      assert_includes response.body, "Required to continue"
    end

    test "update persists essentials and stays on the section" do
      patch admin_website_section_path(section: "essentials"), params: {
        wedding: {
          title: "Updated Title",
          partner1: "Britt",
          partner2: "Alex"
        }
      }

      assert_redirected_to admin_website_section_path(section: "essentials")
      assert_equal "Updated Title", @wedding.reload.title
    end

    test "json update autosaves essentials without redirect" do
      patch admin_website_section_path(section: "essentials"),
            params: { wedding: { title: "Autosaved Title" } },
            as: :json

      assert_response :success
      assert_equal true, response.parsed_body["ok"]
      assert_equal "Autosaved Title", @wedding.reload.title
    end

    test "update persists notifications on the notifications section" do
      patch admin_website_section_path(section: "notifications"), params: {
        wedding: {
          notifications: {
            reminders: {
              enabled: "1",
              send_time: "09:00",
              channels: { email: { enabled: "1" } },
              schedule: {
                "0" => {
                  key: "week_before",
                  days_before: "7",
                  channels: ["email"],
                  audiences: %w[pending_rsvp accepted],
                  email_subject: "One week to go"
                }
              }
            }
          }
        }
      }

      assert_redirected_to admin_website_section_path(section: "notifications")
      @wedding.reload
      assert_equal "09:00", @wedding.notifications.dig("reminders", "send_time")
      assert_equal "One week to go", @wedding.notifications.dig("reminders", "schedule", 0, "email_subject")
      assert_equal %w[pending_rsvp accepted], @wedding.notifications.dig("reminders", "schedule", 0, "audiences")
    end

    test "notifications section shows audiences and email preview" do
      get admin_website_section_path(section: "notifications")

      assert_response :success
      assert_select "input[name*='[audiences][]']"
      assert_select ".admin-email-preview"
      assert_select ".admin-email-preview__subject"
      assert_select ".admin-email-preview__body"
      assert_not_includes response.body, "name=\"wedding[notifications][reminders][audience]\""
    end

    test "update leaves placements alone when the form omits them" do
      asset = create_asset
      @wedding.update!(placements: { "rsvp_portrait" => [asset.id] })

      patch admin_website_section_path(section: "essentials"), params: { wedding: { title: "Renamed" } }

      @wedding.reload
      assert_equal "Renamed", @wedding.title
      assert_equal [asset.id], @wedding.placements["rsvp_portrait"]
    end

    test "essentials date fields are disabled when schedule is locked" do
      travel_to Time.zone.parse("2027-07-10 12:00:00") do
        @wedding.update!(
          date: Date.new(2027, 7, 10),
          ceremony_time: "4:00 PM",
          timezone: "America/Toronto"
        )

        get admin_website_section_path(section: "essentials")

        assert_response :success
        assert_select "input[name='wedding[date]'][disabled]"
        assert_select "input[name='wedding[venue_name]'][disabled]"
        assert_select "input[name='wedding[title]']:not([disabled])"
        assert_match(/locked within 24 hours/i, response.body)
      end
    end

    private

    def create_asset(attrs = {})
      @wedding.wedding_assets.create!(
        {
          object_key: "#{Rails.env}/#{@wedding.id}/site/photos/#{SecureRandom.hex(6)}.webp",
          content_type: "image/webp",
          byte_size: 2048
        }.merge(attrs)
      )
    end
  end
end

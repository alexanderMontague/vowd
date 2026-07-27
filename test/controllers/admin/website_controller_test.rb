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
      assert_includes response.body, "Save changes"
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

    test "update persists notifications on the notifications section" do
      patch admin_website_section_path(section: "notifications"), params: {
        wedding: {
          notifications: {
            reminders: {
              enabled: "1",
              send_time: "09:00",
              audience: "pending_rsvp",
              channels: { email: { enabled: "1" } },
              schedule: {
                "0" => {
                  key: "week_before",
                  days_before: "7",
                  channels: ["email"],
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
    end

    test "update leaves placements alone when the form omits them" do
      asset = create_asset
      @wedding.update!(placements: { "rsvp_portrait" => [asset.id] })

      patch admin_website_section_path(section: "essentials"), params: { wedding: { title: "Renamed" } }

      @wedding.reload
      assert_equal "Renamed", @wedding.title
      assert_equal [asset.id], @wedding.placements["rsvp_portrait"]
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

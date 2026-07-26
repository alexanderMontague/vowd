require "test_helper"

module Admin
  class WebsiteControllerTest < ActionDispatch::IntegrationTest
    setup do
      @wedding = create_wedding(title: "Original Title")
      @admin = create_admin_for(@wedding)
      sign_in_admin(@admin)
    end

    test "show renders website editor for owning admin" do
      get admin_website_path

      assert_response :success
      assert_includes response.body, "Original Title"
      assert_includes response.body, "Add question"
      assert_includes response.body, "Save changes"
      refute_includes response.body, "gallery_images_json"
      # Nested <form> tags close the outer editor form in the browser.
      refute_includes response.body, 'method="dialog"'
    end

    test "unconfigured wedding shows focused setup checklist" do
      @wedding.update!(partner1: nil, partner2: nil, date: nil)

      get admin_website_path

      assert_response :success
      assert_includes response.body, "Set up your wedding"
      assert_includes response.body, "Required to continue"
    end

    test "update persists structured website content" do
      patch admin_website_path, params: {
        wedding: {
          title: "Updated Title",
          partner1: "Britt",
          partner2: "Alex",
          meal_options_text: "Chicken, Vegetarian",
          story: { enabled: "0", title: "Our Story", paragraphs_text: "", closing: "" },
          hero: { tagline: "Join Us", object_key: "development/#{@wedding.id}/site/hero/demo.jpg" },
          rsvp_copy: {
            title: "RSVP",
            description: "Please respond",
            button_text: "RSVP Now",
            lookup_hint: "Use your invite link"
          },
          faq: {
            title: "FAQ",
            subtitle: "Details",
            questions: {
              "0" => { question: "Dress code?", answer: "Cocktail attire" }
            }
          },
          wedding_party: {
            title: "Wedding Party",
            subtitle: "Our people",
            bridesmaids_title: "Bridesmaids",
            groomsmen_title: "Groomsmen",
            bridesmaids: {
              "0" => { name: "Sam", role: "Maid of Honor", relation: "Sister", object_key: "" }
            },
            groomsmen: {}
          },
          photos_page: {
            title: "Photos",
            subtitle: "Moments",
            homepage_enabled: "1",
            homepage_title: "Gallery",
            homepage_limit: "3",
            sections: {
              "0" => {
                title: "Engagement",
                images: {
                  "0" => { object_key: "development/#{@wedding.id}/site/photos/b.jpg", alt: "Park" }
                }
              }
            }
          },
          notifications: {
            reminders: {
              enabled: "1",
              send_time: "09:00",
              audience: "pending_rsvp",
              channels: {
                email: { enabled: "1" }
              },
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

      assert_redirected_to admin_website_path
      @wedding.reload
      assert_equal "Updated Title", @wedding.title
      assert_equal "Join Us", @wedding.hero["tagline"]
      assert_equal "development/#{@wedding.id}/site/hero/demo.jpg", @wedding.hero["object_key"]
      assert_equal "Dress code?", @wedding.faq["questions"].first["question"]
      assert_equal "Sam", @wedding.wedding_party["bridesmaids"].first["name"]
      assert_equal "Engagement", @wedding.photos_page["sections"].first["title"]
      assert_equal true, @wedding.photos_page["homepage_enabled"]
      assert_equal 3, @wedding.photos_page["homepage_limit"]
      assert_equal "09:00", @wedding.notifications.dig("reminders", "send_time")
      assert_equal "One week to go", @wedding.notifications.dig("reminders", "schedule", 0, "email_subject")
    end

    test "gallery tab renders sectioned upload controls" do
      get admin_website_path

      assert_response :success
      assert_includes response.body, "Upload photos"
      assert_includes response.body, "Add section"
      refute_includes response.body, "Photos page"
      refute_includes response.body, "Add blank"
    end
  end
end

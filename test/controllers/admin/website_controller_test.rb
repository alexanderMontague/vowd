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
      assert_not_includes response.body, "gallery_images_json"
      # Nested <form> tags close the outer editor form in the browser.
      assert_not_includes response.body, 'method="dialog"'
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

    test "update persists placements and section asset ids" do
      assets = Array.new(4) { create_asset }

      patch admin_website_path, params: {
        wedding: {
          photos_page: {
            sections: {
              "0" => { title: "Engagement", asset_ids: ["", assets[0].id, assets[1].id] }
            }
          },
          placements: {
            "save_the_date_portrait" => ["", assets[0].id],
            "save_the_date_floating" => ["", assets[1].id, assets[2].id, assets[3].id],
            "rsvp_portrait" => [""]
          }
        }
      }

      assert_redirected_to admin_website_path
      @wedding.reload
      assert_equal [assets[0].id, assets[1].id], @wedding.photos_page["sections"].first["asset_ids"]
      assert_equal [assets[0].id], @wedding.placements["save_the_date_portrait"]
      assert_equal assets[1..3].map(&:id), @wedding.placements["save_the_date_floating"]
      assert_not @wedding.placements.key?("rsvp_portrait")
    end

    test "update clamps a placement to the slot maximum" do
      assets = Array.new(4) { create_asset }

      patch admin_website_path, params: {
        wedding: { placements: { "save_the_date_floating" => assets.map(&:id) } }
      }

      assert_equal assets.first(3).map(&:id), @wedding.reload.placements["save_the_date_floating"]
    end

    test "update leaves placements alone when the form omits them" do
      asset = create_asset
      @wedding.update!(placements: { "rsvp_portrait" => [asset.id] })

      patch admin_website_path, params: { wedding: { title: "Renamed" } }

      @wedding.reload
      assert_equal "Renamed", @wedding.title
      assert_equal [asset.id], @wedding.placements["rsvp_portrait"]
    end

    test "photos tab renders the library, section pickers, and page slots" do
      get admin_website_path

      assert_response :success
      assert_includes response.body, "Upload photos"
      assert_includes response.body, "Add section"
      assert_includes response.body, "Photo library"
      assert_includes response.body, "Envelope open"
      SiteSlots.keys.each { |key| assert_includes response.body, "wedding[placements][#{key}][]" }
    end

    test "photos tab lists library assets and their current placements" do
      asset = create_asset(alt: "On the pier")
      @wedding.update!(placements: { "rsvp_portrait" => [asset.id] })

      get admin_website_path

      assert_response :success
      assert_select %(##{ActionView::RecordIdentifier.dom_id(asset)})
      assert_select %(input.admin-library-asset__alt[value="On the pier"])
      assert_select %(input[name="wedding[placements][rsvp_portrait][]"][value="#{asset.id}"])
    end

    test "photos tab overlays a usage badge container on every library photo" do
      asset = create_asset

      get admin_website_path

      assert_response :success
      # One over the library thumbnail, one over the photo's option in the picker dialog.
      assert_select %(.admin-usage-overlay[data-asset-picker-target="usage"][data-asset-id="#{asset.id}"]), 2
      assert_select %(.admin-thumb-button[data-asset-id="#{asset.id}"])
    end

    test "photos tab gives the lightbox a usage overlay it can point at any photo" do
      get admin_website_path

      assert_response :success
      assert_select %(.admin-gallery-lightbox .admin-usage-overlay[data-asset-id=""]) do |elements|
        assert_equal "usage", elements.sole["data-gallery-lightbox-target"]
        assert_equal "usage", elements.sole["data-asset-picker-target"]
      end
    end

    test "photos tab names each slot picker by page and slot for usage badges" do
      get admin_website_path

      assert_response :success
      SiteSlots.photo_slots.each do |slot|
        page = SiteSlots.page_label(slot.page)
        assert_select %(.admin-asset-picker[data-usage-prefix="#{page}"][data-usage-label="#{slot.label}"])
      end
    end

    test "photos tab leaves section pickers unlabelled so the title field names them" do
      get admin_website_path

      assert_response :success
      assert_select %(.admin-asset-picker[data-usage-prefix="Photos page"][data-usage-label=""])
      assert_select %(input[data-usage-title][name="wedding[photos_page][sections][0][title]"])
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

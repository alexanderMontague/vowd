module Seeds
  class DemoWedding
    SLUG = "britt-and-alex".freeze
    ADMIN_EMAIL = "demo@vowd.test".freeze
    ADMIN_PASSWORD = "password".freeze
    ASSET_DIR = Rails.root.join("db/seed_assets")

    def self.call
      new.call
    end

    def call
      wedding = upsert_wedding!
      upsert_admin!(wedding)
      upsert_content!(wedding)
      import_photos!(wedding)
      upsert_guests!(wedding)
      upsert_events!(wedding)
      PartyBoard.ensure_for!(wedding).each do |board|
        PartyBoards::SyncFromWeddingParty.call(board: board)
      end
      wedding
    end

    private

    def upsert_wedding!
      wedding = Wedding.find_or_initialize_by(id: SLUG)
      wedding.assign_attributes(
        title: "Britt & Alex",
        partner1: "Britt",
        partner2: "Alex",
        initials: "B&A",
        last_name: "Montague",
        date: Date.new(2027, 9, 18),
        ceremony_time: "4:00 PM",
        wedding_duration_hours: 12,
        timezone: "America/Toronto",
        venue_name: "The Glass House",
        venue_address: "120 Lakeshore Road",
        venue_city: "Toronto",
        venue_region: "ON",
        rsvp_deadline: Date.new(2027, 8, 1),
        meal_options: %w[Chicken Vegetarian Steak],
        theme: {
          "key" => SiteThemes::DEFAULT_KEY,
          "font" => "classic",
          "colors" => {},
          "pages" => {}
        }
      )
      wedding.save!
      wedding
    end

    def upsert_admin!(wedding)
      admin = AdminUser.find_or_initialize_by(email: ADMIN_EMAIL)
      admin.assign_attributes(
        name: "Demo Couple",
        password: ADMIN_PASSWORD,
        password_confirmation: ADMIN_PASSWORD,
        wedding: wedding
      )
      admin.save!
      admin
    end

    def upsert_content!(wedding)
      wedding.update!(
        hero: { "tagline" => "September 18, 2027 · Toronto" },
        story: {
          "enabled" => true,
          "title" => "Our story",
          "paragraphs" => [
            "We met on a rainy Tuesday and somehow never stopped talking.",
            "Years later, we're still choosing each other — and we can't wait to celebrate with you."
          ],
          "closing" => "With love, Britt & Alex"
        },
        wedding_party: {
          "title" => "Wedding Party",
          "subtitle" => "The people standing with us",
          "bridesmaids_title" => "Bridesmaids",
          "groomsmen_title" => "Groomsmen",
          "bridesmaids" => [
            { "name" => "Nora Chen", "role" => "Maid of Honour", "relation" => "Sister" },
            { "name" => "Priya Shah", "role" => "Bridesmaid", "relation" => "Friend" }
          ],
          "groomsmen" => [
            { "name" => "Sam Ortiz", "role" => "Best Man", "relation" => "Brother" },
            { "name" => "Jonah Reid", "role" => "Groomsman", "relation" => "Friend" }
          ]
        },
        faq: {
          "title" => "FAQ",
          "subtitle" => "A few helpful details",
          "questions" => [
            { "question" => "What should I wear?", "answer" => "Garden formal — suits and dresses welcome." },
            { "question" => "Are kids invited?", "answer" => "Adults-only celebration, with love." }
          ]
        },
        save_the_date_copy: Wedding::DEFAULT_SAVE_THE_DATE_COPY,
        rsvp_copy: Wedding::DEFAULT_RSVP_COPY,
        photos_page: {
          "title" => "Photos",
          "subtitle" => "A few favorites",
          "homepage_enabled" => true,
          "homepage_title" => "A glimpse",
          "homepage_limit" => 6,
          "sections" => []
        }
      )
    end

    def import_photos!(wedding)
      return unless ASSET_DIR.directory?

      files = {
        "hero.jpg" => "hero",
        "gallery-1.jpg" => "gallery",
        "gallery-2.jpg" => "gallery",
        "dispo.jpg" => "photos"
      }
      asset_ids = []

      files.each_with_index do |(filename, purpose), index|
        path = ASSET_DIR.join(filename)
        next unless path.file?

        # Stable seed keys under the site prefix so the public proxy can serve them.
        key = "#{Rails.env}/#{wedding.id}/site/#{purpose}/seed-#{filename}"

        File.open(path, "rb") do |io|
          DisposableCamera::StorageClient.upload!(
            io: io,
            object_key: key,
            content_type: "image/jpeg"
          )
          io.rewind
          DisposableCamera::StorageClient.upload!(
            io: io,
            object_key: WeddingAssets::ObjectKeyBuilder.thumbnail_key(key),
            content_type: "image/jpeg"
          )
        end

        # Drop legacy seed keys that the public proxy cannot serve.
        wedding.wedding_assets.where("object_key LIKE ?", "%/seed/#{filename}").find_each(&:destroy)

        asset = wedding.wedding_assets.find_or_initialize_by(object_key: key)
        asset.assign_attributes(
          content_type: "image/jpeg",
          byte_size: path.size,
          alt: filename.titleize,
          position: index
        )
        asset.save!
        asset_ids << asset.id
      end

      return if asset_ids.empty?

      portrait_id = asset_ids.first
      floating_ids = asset_ids.drop(1).first(5)
      vase_id = asset_ids[2] || asset_ids.last

      wedding.update!(
        placements: wedding.placements.merge(
          "homepage_hero" => [portrait_id],
          "share_image" => [portrait_id],
          "save_the_date_portrait" => [portrait_id],
          "save_the_date_floating" => floating_ids,
          "save_the_date_vase" => [vase_id],
          "rsvp_portrait" => [portrait_id],
          "rsvp_floating" => floating_ids
        ),
        photos_page: wedding.gallery_content.merge(
          "sections" => [{ "title" => "Favorites", "asset_ids" => asset_ids }]
        )
      )
    end

    def upsert_guests!(wedding)
      household = wedding.households.find_or_create_by!(name: "Chen Family")
      guest = wedding.guests.find_or_initialize_by(email: "nora@example.com")
      guest.assign_attributes(
        first_name: "Nora",
        last_name: "Chen",
        household: household,
        phone_number: "555-0100"
      )
      guest.save!
      if guest.rsvp
        guest.rsvp.update!(
          status: "accepted",
          meal_choice: "Vegetarian",
          song_request: "September — Earth, Wind & Fire",
          notes: "Can't wait to celebrate with you both."
        )
      end

      second = wedding.households.find_or_create_by!(name: "Reid")
      friend = wedding.guests.find_or_initialize_by(email: "jonah@example.com")
      friend.assign_attributes(
        first_name: "Jonah",
        last_name: "Reid",
        household: second
      )
      friend.save!
      friend.rsvp.update!(status: "pending") if friend.rsvp

      third = wedding.households.find_or_create_by!(name: "Park")
      decline = wedding.guests.find_or_initialize_by(email: "mira@example.com")
      decline.assign_attributes(
        first_name: "Mira",
        last_name: "Park",
        household: third
      )
      decline.save!
      decline.rsvp.update!(status: "declined", notes: "Sending love from afar.") if decline.rsvp
    end

    def upsert_events!(wedding)
      ceremony = wedding.events.find_or_initialize_by(name: "Ceremony")
      ceremony.assign_attributes(
        datetime: Time.find_zone!(wedding.timezone).local(2027, 9, 18, 16, 0),
        location: "The Glass House Lawn",
        description: "Outdoor ceremony"
      )
      ceremony.save!

      reception = wedding.events.find_or_initialize_by(name: "Reception")
      reception.assign_attributes(
        datetime: Time.find_zone!(wedding.timezone).local(2027, 9, 18, 18, 30),
        location: "The Glass House Ballroom",
        description: "Dinner and dancing"
      )
      reception.save!
    end
  end
end

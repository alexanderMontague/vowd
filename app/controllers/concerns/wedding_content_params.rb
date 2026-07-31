# Shared reading of wedding content forms. Used by the Wedding essentials editor and
# the Theme site editor so both interpret the same fields identically.
module WeddingContentParams
  extend ActiveSupport::Concern

  CORE_FIELDS = %i[
    title partner1 partner2 initials last_name
    date ceremony_time wedding_duration_hours timezone rsvp_deadline
    venue_name venue_address venue_city venue_region custom_domain
  ].freeze

  private

  def build_wedding_attributes
    permitted = wedding_params
    raw = params.fetch(:wedding, {}).to_unsafe_h
    attrs = permitted.slice(*CORE_FIELDS).to_h

    attrs[:meal_options] = parse_list(permitted[:meal_options_text]) if raw.key?("meal_options_text")
    attrs[:story] = build_story(permitted[:story]) if raw.key?("story")
    attrs[:hero] = build_hero(permitted[:hero]) if raw.key?("hero")
    attrs[:rsvp_copy] = build_rsvp_copy(permitted[:rsvp_copy]) if raw.key?("rsvp_copy")
    attrs[:save_the_date_copy] = build_save_the_date_copy(permitted[:save_the_date_copy]) if raw.key?("save_the_date_copy")
    attrs[:faq] = build_faq(permitted[:faq]) if raw.key?("faq")
    attrs[:wedding_party] = build_wedding_party(permitted[:wedding_party]) if raw.key?("wedding_party")
    attrs[:photos_page] = build_photos_page(permitted[:photos_page]) if raw.key?("photos_page")
    attrs[:placements] = build_placements(permitted[:placements]) if raw.key?("placements")
    attrs[:notifications] = build_notifications(permitted[:notifications]) if raw.key?("notifications")

    attrs
  end

  def wedding_params
    params.require(:wedding).permit(
      *CORE_FIELDS,
      :meal_options_text,
      story: %i[enabled title paragraphs_text closing],
      hero: %i[tagline eyebrow],
      rsvp_copy: %i[title description button_text lookup_hint],
      save_the_date_copy: %i[
        eyebrow announcement formal_note signup_eyebrow signup_prompt
        calendar_button_text submit_button_text
      ],
      faq: [
        :title, :subtitle,
        { questions: %i[question answer] }
      ],
      wedding_party: [
        :title, :subtitle, :bridesmaids_title, :groomsmen_title,
        { bridesmaids: [:name, :role, :relation, :image_url, { asset_id: [] }] },
        { groomsmen: [:name, :role, :relation, :image_url, { asset_id: [] }] }
      ],
      photos_page: [
        :title, :subtitle, :homepage_enabled, :homepage_title, :homepage_limit,
        { sections: [:title, { asset_ids: [], images: %i[alt url] }] }
      ],
      placements: SiteSlots.keys.index_with { [] },
      notifications: {
        reminders: [
          :enabled, :send_time,
          { channels: { email: [:enabled] } },
          { schedule: [:key, :days_before, :email_subject, { channels: [], audiences: [] }] }
        ]
      }
    )
  end

  def build_story(raw)
    data = nested_hash(raw)
    existing = current_wedding.story.presence || Wedding::DEFAULT_STORY

    {
      "enabled" => if data.key?(:enabled)
                     ActiveModel::Type::Boolean.new.cast(data[:enabled])
                   else
                     ActiveModel::Type::Boolean.new.cast(existing["enabled"])
                   end,
      "title" => data.key?(:title) ? data[:title].to_s : existing["title"].to_s,
      "paragraphs" => if data.key?(:paragraphs_text)
                        parse_list(data[:paragraphs_text], separator: "\n")
                      else
                        Array(existing["paragraphs"])
                      end,
      "closing" => if data.key?(:closing)
                     data[:closing].presence
                   else
                     existing["closing"]
                   end
    }
  end

  def build_hero(raw)
    data = nested_hash(raw)
    existing = current_wedding.hero.presence || Wedding::DEFAULT_HERO
    {
      "tagline" => data.key?(:tagline) ? data[:tagline].to_s : existing["tagline"].to_s,
      "eyebrow" => data.key?(:eyebrow) ? data[:eyebrow].to_s : existing["eyebrow"].to_s
    }
  end

  def build_rsvp_copy(raw)
    data = nested_hash(raw)
    existing = current_wedding.rsvp_copy.presence || Wedding::DEFAULT_RSVP_COPY
    {
      "title" => data.key?(:title) ? data[:title].to_s : existing["title"].to_s,
      "description" => data.key?(:description) ? data[:description].to_s : existing["description"].to_s,
      "button_text" => data.key?(:button_text) ? data[:button_text].to_s : existing["button_text"].to_s,
      "lookup_hint" => data.key?(:lookup_hint) ? data[:lookup_hint].to_s : existing["lookup_hint"].to_s
    }
  end

  def build_save_the_date_copy(raw)
    data = nested_hash(raw)
    existing = current_wedding.save_the_date
    {
      "eyebrow" => data.key?(:eyebrow) ? data[:eyebrow].to_s : existing["eyebrow"].to_s,
      "announcement" => data.key?(:announcement) ? data[:announcement].to_s : existing["announcement"].to_s,
      "formal_note" => data.key?(:formal_note) ? data[:formal_note].to_s : existing["formal_note"].to_s,
      "signup_eyebrow" => data.key?(:signup_eyebrow) ? data[:signup_eyebrow].to_s : existing["signup_eyebrow"].to_s,
      "signup_prompt" => data.key?(:signup_prompt) ? data[:signup_prompt].to_s : existing["signup_prompt"].to_s,
      "calendar_button_text" => if data.key?(:calendar_button_text)
                                  data[:calendar_button_text].to_s
                                else
                                  existing["calendar_button_text"].to_s
                                end,
      "submit_button_text" => if data.key?(:submit_button_text)
                                data[:submit_button_text].to_s
                              else
                                existing["submit_button_text"].to_s
                              end
    }
  end

  def build_faq(raw)
    data = nested_hash(raw)
    existing = current_wedding.faq.presence || Wedding::DEFAULT_FAQ
    questions = if data.key?(:questions)
                  nested_list(data[:questions]).filter_map do |item|
                    question = item[:question].to_s.strip
                    answer = item[:answer].to_s.strip
                    next if question.blank? && answer.blank?

                    { "question" => question, "answer" => answer }
                  end
                else
                  Array(existing["questions"])
                end

    {
      "title" => data.key?(:title) ? data[:title].to_s : existing["title"].to_s,
      "subtitle" => data.key?(:subtitle) ? data[:subtitle].to_s : existing["subtitle"].to_s,
      "questions" => questions
    }
  end

  def build_wedding_party(raw)
    data = nested_hash(raw)
    existing = current_wedding.wedding_party.presence || Wedding::DEFAULT_WEDDING_PARTY
    {
      "title" => data.key?(:title) ? data[:title].to_s : existing["title"].to_s,
      "subtitle" => data.key?(:subtitle) ? data[:subtitle].to_s : existing["subtitle"].to_s,
      "bridesmaids_title" => if data.key?(:bridesmaids_title)
                              data[:bridesmaids_title].to_s
                            else
                              existing["bridesmaids_title"].to_s
                            end,
      "groomsmen_title" => if data.key?(:groomsmen_title)
                             data[:groomsmen_title].to_s
                           else
                             existing["groomsmen_title"].to_s
                           end,
      "bridesmaids" => if data.key?(:bridesmaids)
                         build_party_members(data[:bridesmaids])
                       else
                         Array(existing["bridesmaids"])
                       end,
      "groomsmen" => if data.key?(:groomsmen)
                       build_party_members(data[:groomsmen])
                     else
                       Array(existing["groomsmen"])
                     end
    }
  end

  def build_photos_page(raw)
    data = nested_hash(raw)
    existing = current_wedding.gallery_content

    page = {
      "title" => data.key?(:title) ? data[:title].to_s : existing["title"].to_s,
      "subtitle" => data.key?(:subtitle) ? data[:subtitle].to_s : existing["subtitle"].to_s,
      "homepage_enabled" => if data.key?(:homepage_enabled)
                              ActiveModel::Type::Boolean.new.cast(data[:homepage_enabled])
                            else
                              ActiveModel::Type::Boolean.new.cast(existing["homepage_enabled"])
                            end,
      "homepage_title" => if data.key?(:homepage_title)
                            data[:homepage_title].to_s.presence || "Gallery"
                          else
                            existing["homepage_title"].to_s.presence || "Gallery"
                          end,
      "homepage_limit" => if data.key?(:homepage_limit)
                            homepage_gallery_limit(data[:homepage_limit])
                          else
                            homepage_gallery_limit(existing["homepage_limit"])
                          end,
      "sections" => if data.key?(:sections)
                      build_photo_sections(data[:sections])
                    else
                      Array(existing["sections"])
                    end
    }

    page
  end

  def build_photo_sections(raw)
    nested_list(raw).filter_map do |section|
      title = section[:title].to_s.strip
      asset_ids = compact_ids(section[:asset_ids])
      images = build_image_entries(section[:images])
      next if title.blank? && asset_ids.empty? && images.empty?

      { "title" => title, "asset_ids" => asset_ids, "images" => images }
    end
  end

  def homepage_gallery_limit(raw)
    limit = raw.to_i
    limit.positive? ? limit : Wedding::HOMEPAGE_GALLERY_DEFAULT_LIMIT
  end

  # Merge submitted slots into the existing map so a page form that only posts its
  # own slots does not wipe placements configured elsewhere.
  def build_placements(raw)
    data = nested_hash(raw)
    result = (current_wedding.placements.presence || {}).deep_dup

    data.each_key do |key|
      slot = SiteSlots.find(key)
      next unless slot

      ids = compact_ids(data[key]).first(slot.max)
      if ids.any?
        result[slot.key] = ids
      else
        result.delete(slot.key)
      end
    end

    result
  end

  def build_notifications(raw)
    data = nested_hash(raw)
    reminders = nested_hash(data[:reminders])
    channels = nested_hash(reminders[:channels])
    email = nested_hash(channels[:email])

    schedule = nested_list(reminders[:schedule]).filter_map do |row|
      days = row[:days_before].presence
      next if days.blank? && row[:email_subject].to_s.blank?

      audiences = Array(row[:audiences]).map(&:to_s).select do |value|
        WeddingReminders::Configuration::VALID_AUDIENCES.include?(value)
      end
      audiences = [WeddingReminders::Configuration::DEFAULT_AUDIENCE] if audiences.empty?

      {
        "key" => row[:key].presence || "custom_#{SecureRandom.hex(4)}",
        "days_before" => days.to_i,
        "channels" => Array(row[:channels]).map(&:to_s).select { |channel| NotificationDelivery::CHANNELS.include?(channel) }.presence || ["email"],
        "audiences" => audiences,
        "email_subject" => row[:email_subject].to_s
      }
    end

    {
      "reminders" => {
        "enabled" => ActiveModel::Type::Boolean.new.cast(reminders[:enabled]),
        "send_time" => reminders[:send_time].presence || "10:00",
        "channels" => {
          "email" => { "enabled" => ActiveModel::Type::Boolean.new.cast(email[:enabled]) }
        },
        "schedule" => schedule.presence || Wedding::DEFAULT_NOTIFICATIONS.dig("reminders", "schedule")
      }
    }
  end

  def build_image_entries(raw)
    nested_list(raw).filter_map do |item|
      object_key = item[:object_key].to_s.presence
      url = item[:url].to_s.presence
      alt = item[:alt].to_s
      next if object_key.blank? && url.blank?

      entry = { "alt" => alt }
      if object_key
        entry["object_key"] = object_key
      else
        entry["url"] = url
      end
      entry
    end
  end

  def build_party_members(raw)
    nested_list(raw).filter_map do |item|
      name = item[:name].to_s.strip
      next if name.blank?

      member = {
        "name" => name,
        "role" => item[:role].to_s,
        "relation" => item[:relation].to_s
      }
      if (asset_id = compact_ids(item[:asset_id]).first)
        member["asset_id"] = asset_id
      elsif item[:image_url].present?
        member["image_url"] = item[:image_url].to_s
      end
      member
    end
  end

  def compact_ids(raw)
    Array(raw).map { |id| id.to_s.strip }.reject(&:blank?).uniq
  end

  def nested_hash(raw)
    (raw || {}).to_h.with_indifferent_access
  end

  def nested_list(raw)
    case raw
    when Array then raw.map { |item| nested_hash(item) }
    when ActionController::Parameters, Hash
      nested_hash(raw).values.map { |item| nested_hash(item) }
    else
      []
    end
  end

  def parse_list(value, separator: ",")
    value.to_s.split(separator).map(&:strip).reject(&:blank?)
  end
end

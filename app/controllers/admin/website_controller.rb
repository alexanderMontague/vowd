module Admin
  class WebsiteController < Admin::BaseController
    CORE_FIELDS = %i[
      title partner1 partner2 initials last_name
      date ceremony_time wedding_duration_hours timezone rsvp_deadline
      venue_name venue_city venue_region custom_domain
    ].freeze

    def show
      @wedding = current_wedding
    end

    def update
      @wedding = current_wedding
      attrs = build_wedding_attributes

      if @wedding.errors.any?
        assign_form_preview(attrs)
        flash.now[:alert] = @wedding.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
        return
      end

      if @wedding.update(attrs)
        notice = if @wedding.configured?
                   "Wedding details saved. Your admin dashboard is ready."
                 else
                   "Saved. Add both partners and a wedding date to unlock the rest of admin."
                 end
        redirect_to admin_website_path, notice: notice
      else
        flash.now[:alert] = @wedding.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    private

    def build_wedding_attributes
      permitted = wedding_params
      raw = params.fetch(:wedding, {}).to_unsafe_h
      attrs = permitted.slice(*CORE_FIELDS).to_h

      attrs[:meal_options] = parse_list(permitted[:meal_options_text]) if raw.key?("meal_options_text")
      attrs[:story] = build_story(permitted[:story]) if raw.key?("story")
      attrs[:hero] = build_hero(permitted[:hero]) if raw.key?("hero")
      attrs[:gallery] = build_gallery(permitted[:gallery]) if raw.key?("gallery")
      attrs[:rsvp_copy] = build_rsvp_copy(permitted[:rsvp_copy]) if raw.key?("rsvp_copy")
      attrs[:faq] = build_faq(permitted[:faq]) if raw.key?("faq")
      attrs[:wedding_party] = build_wedding_party(permitted[:wedding_party]) if raw.key?("wedding_party")
      attrs[:photos_page] = build_photos_page(permitted[:photos_page]) if raw.key?("photos_page")
      attrs[:notifications] = build_notifications(permitted[:notifications]) if raw.key?("notifications")

      attrs
    end

    def assign_form_preview(attrs)
      @wedding.assign_attributes(attrs)
    end

    def wedding_params
      params.require(:wedding).permit(
        *CORE_FIELDS,
        :meal_options_text,
        story: %i[enabled title paragraphs_text closing],
        hero: %i[tagline object_key image_url],
        gallery: [
          :enabled, :title,
          { images: %i[object_key alt url] }
        ],
        rsvp_copy: %i[title description button_text lookup_hint],
        faq: [
          :title, :subtitle,
          { questions: %i[question answer] }
        ],
        wedding_party: [
          :title, :subtitle, :bridesmaids_title, :groomsmen_title,
          { bridesmaids: %i[name role relation object_key image_url] },
          { groomsmen: %i[name role relation object_key image_url] }
        ],
        photos_page: [
          :title, :subtitle,
          { sections: [:title, { images: %i[object_key alt url] }] }
        ],
        notifications: {
          reminders: [
            :enabled, :send_time, :audience,
            { channels: { email: [:enabled], sms: [:enabled] } },
            { schedule: [:key, :days_before, :email_subject, { channels: [] }] }
          ]
        }
      )
    end

    def build_story(raw)
      data = nested_hash(raw)
      {
        "enabled" => ActiveModel::Type::Boolean.new.cast(data[:enabled]),
        "title" => data[:title].to_s,
        "paragraphs" => parse_list(data[:paragraphs_text], separator: "\n"),
        "closing" => data[:closing].presence
      }
    end

    def build_hero(raw)
      data = nested_hash(raw)
      hero = { "tagline" => data[:tagline].to_s }
      if data[:object_key].present?
        hero["object_key"] = data[:object_key].to_s
      elsif data[:image_url].present?
        hero["image_url"] = data[:image_url].to_s
      end
      hero
    end

    def build_gallery(raw)
      data = nested_hash(raw)
      {
        "enabled" => ActiveModel::Type::Boolean.new.cast(data[:enabled]),
        "title" => data[:title].to_s,
        "images" => build_image_entries(data[:images])
      }
    end

    def build_rsvp_copy(raw)
      data = nested_hash(raw)
      {
        "title" => data[:title].to_s,
        "description" => data[:description].to_s,
        "button_text" => data[:button_text].to_s,
        "lookup_hint" => data[:lookup_hint].to_s
      }
    end

    def build_faq(raw)
      data = nested_hash(raw)
      questions = nested_list(data[:questions]).filter_map do |item|
        question = item[:question].to_s.strip
        answer = item[:answer].to_s.strip
        next if question.blank? && answer.blank?

        { "question" => question, "answer" => answer }
      end

      {
        "title" => data[:title].to_s,
        "subtitle" => data[:subtitle].to_s,
        "questions" => questions
      }
    end

    def build_wedding_party(raw)
      data = nested_hash(raw)
      {
        "title" => data[:title].to_s,
        "subtitle" => data[:subtitle].to_s,
        "bridesmaids_title" => data[:bridesmaids_title].to_s,
        "groomsmen_title" => data[:groomsmen_title].to_s,
        "bridesmaids" => build_party_members(data[:bridesmaids]),
        "groomsmen" => build_party_members(data[:groomsmen])
      }
    end

    def build_photos_page(raw)
      data = nested_hash(raw)
      sections = nested_list(data[:sections]).filter_map do |section|
        title = section[:title].to_s.strip
        images = build_image_entries(section[:images])
        next if title.blank? && images.empty?

        { "title" => title, "images" => images }
      end

      {
        "title" => data[:title].to_s,
        "subtitle" => data[:subtitle].to_s,
        "sections" => sections
      }
    end

    def build_notifications(raw)
      data = nested_hash(raw)
      reminders = nested_hash(data[:reminders])
      channels = nested_hash(reminders[:channels])
      email = nested_hash(channels[:email])
      sms = nested_hash(channels[:sms])

      schedule = nested_list(reminders[:schedule]).filter_map do |row|
        days = row[:days_before].presence
        next if days.blank? && row[:email_subject].to_s.blank?

        {
          "key" => row[:key].presence || "custom_#{SecureRandom.hex(4)}",
          "days_before" => days.to_i,
          "channels" => Array(row[:channels]).map(&:to_s).reject(&:blank?).presence || ["email"],
          "email_subject" => row[:email_subject].to_s
        }
      end

      {
        "reminders" => {
          "enabled" => ActiveModel::Type::Boolean.new.cast(reminders[:enabled]),
          "send_time" => reminders[:send_time].presence || "10:00",
          "audience" => reminders[:audience].presence || "pending_rsvp",
          "channels" => {
            "email" => { "enabled" => ActiveModel::Type::Boolean.new.cast(email[:enabled]) },
            "sms" => { "enabled" => ActiveModel::Type::Boolean.new.cast(sms[:enabled]) }
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
        if item[:object_key].present?
          member["object_key"] = item[:object_key].to_s
        elsif item[:image_url].present?
          member["image_url"] = item[:image_url].to_s
        end
        member
      end
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
end

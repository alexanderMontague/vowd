# Maps each library photo to the human labels of every place it appears on the
# guest site. Labels must match `asset_picker_controller` so live edits overlay
# the saved baseline without duplicating badges.
class AssetUsageIndex
  LABEL_SEPARATOR = " · "
  UNTITLED_SECTION = "Untitled section"

  def self.call(wedding)
    new(wedding).to_h
  end

  def initialize(wedding)
    @wedding = wedding
  end

  def to_h
    labels = Hash.new { |hash, key| hash[key] = [] }

    add_placements!(labels)
    add_gallery_sections!(labels)
    add_party_members!(labels)

    labels.transform_values(&:uniq)
  end

  private

  def add_placements!(labels)
    SiteSlots.photo_slots.each do |slot|
      label = join(SiteSlots.page_label(slot.page), slot.label)
      Array(@wedding.placements.presence&.dig(slot.key)).each do |asset_id|
        add(labels, asset_id, label)
      end
    end
  end

  def add_gallery_sections!(labels)
    Array(@wedding.gallery_content["sections"]).each do |section|
      title = section["title"].to_s.strip.presence || UNTITLED_SECTION
      label = join("Photos page", title)
      Array(section["asset_ids"]).each { |asset_id| add(labels, asset_id, label) }
    end
  end

  def add_party_members!(labels)
    party = @wedding.wedding_party.presence || {}

    Array(party["bridesmaids"]).each do |member|
      add_party_member!(labels, member, "Bridesmaid")
    end
    Array(party["groomsmen"]).each do |member|
      add_party_member!(labels, member, "Groomsman")
    end
  end

  def add_party_member!(labels, member, prefix)
    asset_id = member.to_h["asset_id"].presence
    return if asset_id.blank?

    name = member.to_h["name"].to_s.strip.presence || UNTITLED_SECTION
    add(labels, asset_id, join(prefix, name))
  end

  def add(labels, asset_id, label)
    id = asset_id.to_s.strip
    return if id.blank?

    labels[id] << label unless labels[id].include?(label)
  end

  def join(prefix, name)
    [prefix, name].filter_map { |part| part.to_s.presence }.join(LABEL_SEPARATOR)
  end
end

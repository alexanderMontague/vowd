module PartyBoards
  class SyncFromWeddingParty
    def self.call(board:)
      new(board: board).call
    end

    def initialize(board:)
      @board = board
      @wedding = board.wedding
    end

    def call
      group = @board.wedding_party_group
      party = @wedding.wedding_party.presence || Wedding::DEFAULT_WEDDING_PARTY
      members = Array(party[group])

      members.each_with_index do |raw, index|
        data = raw.to_h.stringify_keys
        name = data["name"].to_s.strip
        next if name.blank?

        key = "#{group}:#{name.downcase}"
        member = @board.members.find_or_initialize_by(wedding_party_key: key)
        member.assign_attributes(
          wedding_id: @wedding.id,
          name: name,
          role: data["role"].to_s.presence,
          source: "wedding_party",
          position: index
        )
        member.save!
      end

      @board
    end
  end
end

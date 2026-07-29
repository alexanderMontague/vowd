class CreatePartyPlanningTables < ActiveRecord::Migration[7.1]
  def change
    create_table :party_boards, id: :string do |t|
      t.string :wedding_id, null: false
      t.string :kind, null: false
      t.string :title, null: false
      t.string :share_token, null: false
      t.string :status, null: false, default: "active"
      t.text :notes
      t.timestamps
    end
    add_index :party_boards, [:wedding_id, :kind], unique: true
    add_index :party_boards, :share_token, unique: true
    add_index :party_boards, :wedding_id

    create_table :party_members, id: :string do |t|
      t.string :party_board_id, null: false
      t.string :wedding_id, null: false
      t.string :name, null: false
      t.string :role
      t.string :email
      t.string :phone_number
      t.string :source, null: false, default: "custom"
      t.string :wedding_party_key
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :party_members, :party_board_id
    add_index :party_members, :wedding_id
    add_index :party_members, [:party_board_id, :wedding_party_key], unique: true

    create_table :party_ideas, id: :string do |t|
      t.string :party_board_id, null: false
      t.string :wedding_id, null: false
      t.string :title, null: false
      t.text :body
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :party_ideas, :party_board_id
    add_index :party_ideas, :wedding_id

    create_table :party_itinerary_items, id: :string do |t|
      t.string :party_board_id, null: false
      t.string :wedding_id, null: false
      t.date :occurs_on
      t.string :starts_at_text
      t.string :title, null: false
      t.string :location
      t.text :notes
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :party_itinerary_items, :party_board_id
    add_index :party_itinerary_items, :wedding_id

    create_table :party_polls, id: :string do |t|
      t.string :party_board_id, null: false
      t.string :wedding_id, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "open"
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :party_polls, :party_board_id
    add_index :party_polls, :wedding_id

    create_table :party_poll_options, id: :string do |t|
      t.string :party_poll_id, null: false
      t.string :wedding_id, null: false
      t.string :title, null: false
      t.string :price_text
      t.text :notes
      t.string :url
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :party_poll_options, :party_poll_id
    add_index :party_poll_options, :wedding_id

    create_table :party_poll_votes, id: :string do |t|
      t.string :party_poll_id, null: false
      t.string :party_poll_option_id, null: false
      t.string :party_member_id, null: false
      t.string :wedding_id, null: false
      t.timestamps
    end
    add_index :party_poll_votes, [:party_poll_id, :party_member_id], unique: true
    add_index :party_poll_votes, :party_poll_option_id
    add_index :party_poll_votes, :wedding_id
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_07_28_021319) do
  create_table "admin_users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "wedding_id", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["wedding_id"], name: "index_admin_users_on_wedding_id", unique: true
  end

  create_table "disposable_photos", id: :string, force: :cascade do |t|
    t.string "wedding_id", null: false
    t.integer "guest_id"
    t.string "object_key", null: false
    t.string "content_type", null: false
    t.integer "byte_size", null: false
    t.boolean "flash_enabled", default: false, null: false
    t.datetime "captured_at", null: false
    t.string "source_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guest_id"], name: "index_disposable_photos_on_guest_id"
    t.index ["object_key"], name: "index_disposable_photos_on_object_key", unique: true
    t.index ["wedding_id", "created_at"], name: "index_disposable_photos_on_wedding_id_and_created_at"
  end

  create_table "events", force: :cascade do |t|
    t.string "wedding_id", null: false
    t.string "name", null: false
    t.datetime "datetime"
    t.string "location"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wedding_id"], name: "index_events_on_wedding_id"
  end

  create_table "guests", force: :cascade do |t|
    t.string "wedding_id", null: false
    t.integer "household_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "invite_code", null: false
    t.text "address"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["household_id"], name: "index_guests_on_household_id"
    t.index ["wedding_id", "invite_code"], name: "index_guests_on_wedding_id_and_invite_code", unique: true
    t.index ["wedding_id"], name: "index_guests_on_wedding_id"
  end

  create_table "households", force: :cascade do |t|
    t.string "wedding_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wedding_id"], name: "index_households_on_wedding_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.integer "guest_id", null: false
    t.datetime "sent_at"
    t.datetime "opened_at"
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guest_id"], name: "index_invitations_on_guest_id"
  end

  create_table "notification_deliveries", force: :cascade do |t|
    t.integer "guest_id", null: false
    t.string "wedding_id", null: false
    t.string "reminder_key", null: false
    t.string "channel", null: false
    t.date "scheduled_for", null: false
    t.string "status", default: "queued", null: false
    t.datetime "sent_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guest_id", "wedding_id", "reminder_key", "channel"], name: "index_notification_deliveries_uniqueness", unique: true
    t.index ["guest_id"], name: "index_notification_deliveries_on_guest_id"
  end

  create_table "rsvps", force: :cascade do |t|
    t.integer "guest_id", null: false
    t.string "status", default: "pending", null: false
    t.string "meal_choice"
    t.text "dietary_restrictions"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "song_request"
    t.index ["guest_id", "status"], name: "index_rsvps_on_guest_id_and_status"
    t.index ["guest_id"], name: "index_rsvps_on_guest_id"
  end

  create_table "save_the_date_signups", force: :cascade do |t|
    t.string "wedding_id", null: false
    t.integer "guest_id"
    t.string "name"
    t.string "email", null: false
    t.string "phone_number"
    t.datetime "matched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guest_id"], name: "index_save_the_date_signups_on_guest_id"
    t.index ["wedding_id", "email"], name: "index_save_the_date_signups_on_wedding_id_and_email"
  end

  create_table "wedding_assets", id: :string, force: :cascade do |t|
    t.string "wedding_id", null: false
    t.string "object_key", null: false
    t.string "content_type", null: false
    t.integer "byte_size"
    t.string "alt"
    t.string "caption"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["object_key"], name: "index_wedding_assets_on_object_key", unique: true
    t.index ["wedding_id", "position"], name: "index_wedding_assets_on_wedding_id_and_position"
  end

  create_table "wedding_metadata", id: :string, force: :cascade do |t|
    t.string "wedding_id"
    t.string "key"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wedding_id", "key"], name: "index_wedding_metadata_on_wedding_id_and_key", unique: true
    t.index ["wedding_id"], name: "index_wedding_metadata_on_wedding_id"
  end

  create_table "weddings", id: :string, force: :cascade do |t|
    t.string "title", null: false
    t.string "partner1"
    t.string "partner2"
    t.string "initials"
    t.string "last_name"
    t.date "date"
    t.string "ceremony_time"
    t.integer "wedding_duration_hours", default: 12, null: false
    t.string "venue_name"
    t.string "venue_city"
    t.string "venue_region"
    t.date "rsvp_deadline"
    t.string "timezone", default: "America/Toronto", null: false
    t.json "meal_options", default: [], null: false
    t.json "story", default: {}, null: false
    t.json "hero", default: {}, null: false
    t.json "gallery", default: {}, null: false
    t.json "rsvp_copy", default: {}, null: false
    t.json "faq", default: {}, null: false
    t.json "wedding_party", default: {}, null: false
    t.json "photos_page", default: {}, null: false
    t.json "notifications", default: {}, null: false
    t.string "custom_domain"
    t.datetime "custom_domain_verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "placements", default: {}, null: false
    t.json "theme", default: {}, null: false
    t.json "save_the_date_copy", default: {}, null: false
    t.string "venue_address"
    t.index ["custom_domain"], name: "index_weddings_on_custom_domain", unique: true
  end

  add_foreign_key "admin_users", "weddings"
  add_foreign_key "disposable_photos", "guests"
  add_foreign_key "guests", "households"
  add_foreign_key "invitations", "guests"
  add_foreign_key "notification_deliveries", "guests"
  add_foreign_key "rsvps", "guests"
  add_foreign_key "save_the_date_signups", "guests"
end

class CreateWeddingsAndLinkAdminUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :weddings, id: :string do |t|
      t.string :title, null: false
      t.string :partner1
      t.string :partner2
      t.string :initials
      t.string :last_name
      t.date :date
      t.string :ceremony_time
      t.integer :wedding_duration_hours, default: 12, null: false
      t.string :venue_name
      t.string :venue_city
      t.string :venue_region
      t.date :rsvp_deadline
      t.string :timezone, default: "America/Toronto", null: false
      t.json :meal_options, default: [], null: false
      t.json :story, default: {}, null: false
      t.json :hero, default: {}, null: false
      t.json :gallery, default: {}, null: false
      t.json :rsvp_copy, default: {}, null: false
      t.json :faq, default: {}, null: false
      t.json :wedding_party, default: {}, null: false
      t.json :photos_page, default: {}, null: false
      t.json :notifications, default: {}, null: false
      t.string :custom_domain
      t.datetime :custom_domain_verified_at

      t.timestamps
    end

    add_index :weddings, :custom_domain, unique: true

    # Existing admins are cleared — accounts are created via platform signup.
    reversible do |dir|
      dir.up { execute "DELETE FROM admin_users" }
    end

    add_column :admin_users, :wedding_id, :string, null: false
    add_index :admin_users, :wedding_id, unique: true
    add_foreign_key :admin_users, :weddings
  end
end

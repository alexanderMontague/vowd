class CreateAdminNotificationDeliveries < ActiveRecord::Migration[7.1]
  def change
    create_table :admin_notification_deliveries do |t|
      t.string :wedding_id, null: false
      t.string :kind, null: false
      t.string :status, null: false, default: "queued"
      t.datetime :sent_at
      t.text :error_message

      t.timestamps
    end

    add_index :admin_notification_deliveries,
              %i[wedding_id kind],
              unique: true,
              name: "index_admin_notification_deliveries_uniqueness"
    add_foreign_key :admin_notification_deliveries, :weddings
  end
end

class AddBillingToWeddings < ActiveRecord::Migration[7.1]
  def change
    add_column :weddings, :billing_status, :string, null: false, default: "trialing"
    add_column :weddings, :trial_ends_at, :datetime
    add_column :weddings, :stripe_customer_id, :string
    add_column :weddings, :stripe_subscription_id, :string
    add_column :weddings, :billing_period_end, :datetime

    add_index :weddings, :stripe_customer_id, unique: true
    add_index :weddings, :stripe_subscription_id, unique: true

    reversible do |dir|
      dir.up do
        # Existing sites stay unlocked; new signups start a trial via WeddingRegistration.
        execute <<~SQL.squish
          UPDATE weddings
          SET billing_status = 'active'
          WHERE billing_status = 'trialing'
        SQL
      end
    end
  end
end

class AddVenueAddressToWeddings < ActiveRecord::Migration[7.1]
  def change
    add_column :weddings, :venue_address, :string
  end
end

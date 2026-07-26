class AddPlacementsToWeddings < ActiveRecord::Migration[7.1]
  def change
    add_column :weddings, :placements, :json, null: false, default: {}
  end
end

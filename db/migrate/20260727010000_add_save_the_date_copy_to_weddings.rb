class AddSaveTheDateCopyToWeddings < ActiveRecord::Migration[7.1]
  def change
    add_column :weddings, :save_the_date_copy, :json, null: false, default: {}
  end
end

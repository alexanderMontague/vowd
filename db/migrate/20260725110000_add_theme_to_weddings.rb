class AddThemeToWeddings < ActiveRecord::Migration[7.1]
  def change
    add_column :weddings, :theme, :json, default: {}, null: false
  end
end

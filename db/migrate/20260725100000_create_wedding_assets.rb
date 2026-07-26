class CreateWeddingAssets < ActiveRecord::Migration[7.1]
  def change
    create_table :wedding_assets, id: :string do |t|
      t.string :wedding_id, null: false
      t.string :object_key, null: false
      t.string :content_type, null: false
      t.integer :byte_size
      t.string :alt
      t.string :caption
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :wedding_assets, :object_key, unique: true
    add_index :wedding_assets, %i[wedding_id position]
  end
end

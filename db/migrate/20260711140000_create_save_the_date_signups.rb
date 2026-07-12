class CreateSaveTheDateSignups < ActiveRecord::Migration[7.1]
  def change
    create_table :save_the_date_signups do |t|
      t.string :wedding_id, null: false
      t.references :guest, null: true, foreign_key: true
      t.string :name
      t.string :email, null: false
      t.string :phone_number
      t.datetime :matched_at

      t.timestamps
    end

    add_index :save_the_date_signups, [:wedding_id, :email]
  end
end

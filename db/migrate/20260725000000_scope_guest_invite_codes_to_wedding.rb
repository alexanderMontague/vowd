class ScopeGuestInviteCodesToWedding < ActiveRecord::Migration[7.1]
  def up
    remove_index :guests, :invite_code
    add_index :guests, %i[wedding_id invite_code], unique: true
  end

  def down
    remove_index :guests, %i[wedding_id invite_code]
    add_index :guests, :invite_code, unique: true
  end
end

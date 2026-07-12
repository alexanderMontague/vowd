class AddSongRequestToRsvps < ActiveRecord::Migration[7.1]
  def change
    add_column :rsvps, :song_request, :text
  end
end

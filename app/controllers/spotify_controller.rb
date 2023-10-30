class SpotifyController < ApplicationController
  # :nocov:
  def callback
    spotify_user = RSpotify::User.new(request.env['omniauth.auth'])

    waterfire_user = RSpotify::User.find("waterfireprov")

    waterfire_playlist = RSpotify::Playlist.find_by_id("6zm9Di0Bxaw9EZ5eAVML6Q")

    track = RSpotify::Track.find("3wan7OUnxFsdLj5R5OH8NX")
    waterfire_playlist.replace_tracks!([track])

    playlist_ids = []

    offset = 0

    while offset < 200
      playlist_ids.concat(waterfire_user.playlists(offset: offset).map(&:id))
      offset += 20
    end

    track_ids = []

    valid_years = (2017..2050).to_a.map(&:to_s)

    playlist_ids.each_with_index do |playlist_id, index|
      playlist = RSpotify::Playlist.find_by_id(playlist_id)

      # skip playlists without a date in them
      next unless valid_years.any? { playlist.name.include?(_1) }

      puts "loading playlist #{index}"

      track_ids.concat(RSpotify::Playlist.find_by_id(playlist_id).tracks_added_at.keys)
    end

    track_ids.uniq.last(500).each_slice(10) do |track_id_group|
      waterfire_playlist.add_tracks!(track_id_group.map { "spotify:track:#{_1}"} )
    end

    redirect_to(root_path, flash: {notice: "Waterfire playlist synced"})
  end
  # :nocov:
end
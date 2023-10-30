require 'rspotify/oauth'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :spotify, Rails.application.config.local["spotify_client_id"], Rails.application.config.local["spotify_client_secret"], scope: 'user-read-email playlist-modify-public user-library-read user-library-modify playlist-modify-private'
end

OmniAuth.config.allowed_request_methods = [:post, :get]
# frozen_string_literal: true

class GoogleAccount < ApplicationRecord
  belongs_to :user
  has_many :google_calendars

  def refresh!
    response =
      HTTParty.post("https://accounts.google.com/o/oauth2/token",
        body: {
          grant_type: "refresh_token",
          client_id: ENV["GOOGLE_CLIENT_ID"],
          client_secret: ENV["GOOGLE_CLIENT_SECRET"],
          refresh_token: refresh_token
        })

    response = JSON.parse(response.body)
    update(
      access_token: response["access_token"],
      expires_at: Time.now + response["expires_in"].to_i.seconds
    )
    save
  end
end

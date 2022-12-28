# frozen_string_literal: true

class GoogleAccount < ApplicationRecord
  has_many :google_calendars

  def self.client
    Signet::OAuth2::Client.new(client_options)
  end

  def self.client_options
    {
      client_id: ENV["GOOGLE_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"],
      authorization_uri: "https://accounts.google.com/o/oauth2/auth",
      token_credential_uri: "https://accounts.google.com/o/oauth2/token",
      scope: 
        "#{Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY} " \
        "#{Google::Apis::PeopleV1::AUTH_CONTACTS_READONLY} " \
        "#{Google::Apis::PeopleV1::AUTH_USERINFO_PROFILE} " \
        "#{Google::Apis::PeopleV1::AUTH_CONTACTS_OTHER_READONLY} " \
        "#{Google::Apis::GmailV1::AUTH_GMAIL_READONLY}",
      redirect_uri: ENV["GOOGLE_REDIRECT_URI"],
      access_type: "offline"
    }
  end

  def refresh!
    begin
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
    rescue => e
      Log.create(
        globalid: to_global_id,
        event: "refresh_error",
        message: e.message
      )
    end
  end
end

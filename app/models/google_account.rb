# frozen_string_literal: true

class GoogleAccount < ApplicationRecord
  has_many :google_calendars

  def healthy?
    Log.where(globalid: to_global_id.to_s, event: "fetch_success").last.created_at > DateTime.now - 2.hours
  end

  def pretty_name
    if email == "joel@hawksley.org"
      "personal"
    else
      "work"
    end
  end

  def self.refresh_all
    all.each(&:refresh!)
  end

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
        "#{Google::Apis::PeopleV1::AUTH_USERINFO_PROFILE}",
      redirect_uri: ENV["GOOGLE_REDIRECT_URI"],
      access_type: "offline"
    }
  end

  def refresh!
    refresh_token! if expires_at < Time.now
  end

  private

  def refresh_token!
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

    Log.create(
      globalid: to_global_id,
      event: "refresh_success",
      message: ""
    )
  rescue => e
    Log.create(
      globalid: to_global_id,
      event: "refresh_error",
      message: e.message + response.to_s
    )
  end
end

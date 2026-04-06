# frozen_string_literal: true

class GoogleAccount < ActiveRecord::Base
  belongs_to :account
  has_many :calendars, dependent: :destroy

  encrypts :access_token
  encrypts :refresh_token
  encrypts :email
  encrypts :google_uid, deterministic: true

  validates :google_uid, presence: true, uniqueness: {scope: :account_id}
  validates :email, presence: true

  def token_expired?
    token_expires_at.present? && token_expires_at < Time.current
  end

  def refresh_access_token!
    oauth_client = OAuth2::Client.new(
      ENV.fetch("GOOGLE_CLIENT_ID"),
      ENV.fetch("GOOGLE_CLIENT_SECRET"),
      site: "https://accounts.google.com",
      token_url: "/o/oauth2/token"
    )

    token = OAuth2::AccessToken.new(oauth_client, access_token, refresh_token: refresh_token)
    new_token = token.refresh!

    update!(
      access_token: new_token.token,
      refresh_token: new_token.refresh_token || refresh_token,
      token_expires_at: Time.at(new_token.expires_at)
    )
  end

  def valid_access_token
    refresh_access_token! if token_expired?
    access_token
  end
end

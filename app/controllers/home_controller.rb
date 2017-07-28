  class HomeController < ApplicationController
  def index
  end

  def display
    authenticate_user!
  end

  def redirect
    authenticate_user!

    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY,
      access_type: 'offline',
      redirect_uri: callback_url
    })

    redirect_to(client.authorization_uri.to_s)
  end

  def callback
    authenticate_user!

    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      access_type: 'offline',
      redirect_uri: callback_url,
      code: params[:code]
    })

    response = client.fetch_access_token!

    current_user.update(google_authorization: response)

    redirect_to(root_path, flash: { notice: 'Google Account connected' })
  end
end

# frozen_string_literal: true

class HomeController < ApplicationController
  def index
  end

  def redirect
    client = Signet::OAuth2::Client.new(GoogleService.client_options)

    redirect_to(client.authorization_uri.to_s)
  end

  def callback
    client = Signet::OAuth2::Client.new(GoogleService.client_options)
    client.code = params[:code]

    response = client.fetch_access_token!

    people_service = Google::Apis::PeopleV1::PeopleServiceService.new
    people_service.authorization = client

    person =
      people_service
        .get_person("people/me", person_fields: "emailAddresses")

    email_address =
      if person.email_addresses
        person.email_addresses.find { |email_address| email_address.metadata.primary }.value
      else
        person.resource_name
      end

    existing_account = GoogleAccount.find_by(email: email_address)

    if existing_account
      existing_account.update(
        access_token: response["access_token"],
        refresh_token: response["refresh_token"].to_s,
        expires_at: Time.now + response["expires_in"].to_i.seconds
      )
    else
      GoogleAccount.create(
        email: email_address,
        access_token: response["access_token"],
        refresh_token: response["refresh_token"].to_s,
        expires_at: Time.now + response["expires_in"].to_i.seconds
      )
    end

    redirect_to(root_path, flash: {notice: "Google Account connected"})
  end
end

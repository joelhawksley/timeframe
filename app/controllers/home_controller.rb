  class HomeController < ApplicationController
  def index
  end

  def display
    authenticate_user!

    respond_to do |format|
      format.html
      format.json do
        render json: current_user.render_json_payload
      end
    end
  end

  def display_from_token
    render json: User.find_by(token: params[:token]).render_json_payload
  end

  def redirect
    authenticate_user!

    client = Signet::OAuth2::Client.new(CalendarService.client_options)

    redirect_to(client.authorization_uri.to_s)
  end

  def callback
    authenticate_user!

    client = Signet::OAuth2::Client.new(CalendarService.client_options)
    client.code = params[:code]

    response = client.fetch_access_token!

    people_service = Google::Apis::PeopleV1::PeopleServiceService.new
    people_service.authorization = client

    person =
      people_service.
        get_person("people/me", person_fields: "emailAddresses")

    email_address =
      if person.email_addresses
        email_addresses.find { |email_address| email_address.metadata.primary }.value
      else
        person.resource_name
      end

    existing_account = current_user.google_accounts.find_by(email: email_address)

    if existing_account
      existing_account.update(google_authorization: response)
    else
      current_user.google_accounts.create(email: email_address, google_authorization: response)
    end

    redirect_to(root_path, flash: { notice: 'Google Account connected' })
  end
end

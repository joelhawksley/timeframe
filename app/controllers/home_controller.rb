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

    current_user.update(google_authorization: response)

    redirect_to(root_path, flash: { notice: 'Google Account connected' })
  end
end

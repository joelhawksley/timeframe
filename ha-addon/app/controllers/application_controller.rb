# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :auto_sign_in_default_user!
  before_action :authenticate_user!

  private

  def auto_sign_in_default_user!
    return if warden.authenticated?(:user)

    user = User.first
    unless user
      account = Account.first || Account.create!(name: "Home")

      unless account.locations.exists?
        config = begin
          HomeAssistantApi.new.config_data
        rescue
          {}
        end

        account.locations.create!(
          name: config[:location_name] || "Home",
          latitude: config[:latitude] || 0,
          longitude: config[:longitude] || 0,
          time_zone: config[:time_zone] || "America/Chicago"
        )
      end

      user = User.create!(email: "homeassistant@timeframe.local")
      user.accounts << account
    end

    warden.set_user(user, scope: :user)
  end

  def authenticate_user!
    head :unauthorized unless current_user
  end

  def current_user
    warden&.user(:user)
  end

  def warden
    request.env["warden"]
  end
end

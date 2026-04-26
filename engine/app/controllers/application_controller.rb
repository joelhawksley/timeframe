# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :authenticate_user!

  private

  # Override in host apps to provide authentication.
  # ha-addon: auto-sign-in via warden
  # cloud: Devise authenticate_user!
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

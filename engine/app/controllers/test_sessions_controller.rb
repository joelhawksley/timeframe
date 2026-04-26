# frozen_string_literal: true

class TestSessionsController < ApplicationController
  skip_before_action :auto_sign_in_default_user!, raise: false
  skip_before_action :authenticate_user!

  def sign_in
    user = User.find_or_create_by!(email: "test@timeframe.local")
    account = Account.find_or_create_by!(name: "Test")
    user.accounts << account unless user.accounts.include?(account)
    account.locations.find_or_create_by!(name: "Test Location") do |l|
      l.latitude = 38.4937
      l.longitude = -98.7675
      l.time_zone = "America/Chicago"
    end

    warden.set_user(user, scope: :user)
    redirect_to root_path
  end
end

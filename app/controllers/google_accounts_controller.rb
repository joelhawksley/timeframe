# frozen_string_literal: true

class GoogleAccountsController < ApplicationController
  before_action :set_account, only: [:destroy]

  def create
    auth = request.env["omniauth.auth"]
    account = current_user.accounts.find(session.fetch(:oauth_account_id))

    google_account = account.google_accounts.find_or_initialize_by(google_uid: auth["uid"])
    google_account.update!(
      email: auth["info"]["email"],
      access_token: auth["credentials"]["token"],
      refresh_token: auth["credentials"]["refresh_token"] || google_account.refresh_token,
      token_expires_at: Time.at(auth["credentials"]["expires_at"])
    )

    SyncGoogleAccountCalendarsJob.perform_later(google_account.id)

    redirect_to account_calendars_path(account), notice: "Google account #{google_account.email} connected. Syncing calendars..."
  end

  def destroy
    google_account = @account.google_accounts.find(params[:id])
    google_account.destroy
    redirect_to account_calendars_path(@account), notice: "Google account disconnected."
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:account_id])
  end
end

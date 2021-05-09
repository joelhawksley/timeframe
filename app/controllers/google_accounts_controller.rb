# frozen_string_literal: true

class GoogleAccountsController < ApplicationController
  before_action :authenticate_user!

  def update
    current_user
      .google_accounts
      .find(params[:id])
      .update(google_account_params)

    redirect_to(root_path, flash: {notice: "Updated"})
  end

  private

  def google_account_params
    params.require(:google_account).permit(:email_enabled)
  end
end

# frozen_string_literal: true

class CalendarsController < ApplicationController
  before_action :set_account

  def index
    @google_accounts = @account.google_accounts.includes(:calendars)
    @url_calendars = @account.calendars.url_source
  end

  def new
    @calendar = @account.calendars.new(source_type: "url")
  end

  def create
    @calendar = @account.calendars.new(calendar_params)
    @calendar.source_type = "url"

    if @calendar.save
      redirect_to account_calendars_path(@account), notice: "Calendar added and syncing."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    calendar = @account.calendars.find(params[:id])
    calendar.destroy
    redirect_to account_calendars_path(@account), notice: "Calendar removed."
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:account_id])
    session[:oauth_account_id] = @account.id
  end

  def calendar_params
    params.require(:calendar).permit(:name, :url)
  end
end

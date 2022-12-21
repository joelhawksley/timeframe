# frozen_string_literal: true

class GoogleCalendarsController < ApplicationController
  def update
    GoogleCalendar.find(params[:id]).update(google_calendar_params)

    redirect_to(root_path, flash: {notice: "Updated"})
  end

  private

  def google_calendar_params
    params.require(:google_calendar).permit(:enabled, :icon, :letter)
  end
end

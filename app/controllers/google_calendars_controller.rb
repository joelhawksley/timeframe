class GoogleCalendarsController < ApplicationController
  before_action :authenticate_user!

  def update
    current_user.
      google_calendars.
      find(params[:id]).
      update(google_calendar_params)

    redirect_to(root_path, flash: { notice: 'Updated' })
  end

  private

  def google_calendar_params
    params.require(:google_calendar).permit(:enabled, :icon, :letter)
  end
end

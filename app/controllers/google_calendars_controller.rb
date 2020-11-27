class GoogleCalendarsController < ApplicationController
  before_action :authenticate_user!

  def update
    current_user.
      google_calendars.
      find(params[:id]).
      update(enabled: params[:google_calendar][:enabled])

    redirect_to(root_path, flash: { notice: 'Updated' })
  end

  private

  def google_calendar_params
    params.require(:user).permit(:latitude, :longitude)
  end
end

# :nocov:
class DisplaysController < ApplicationController
  layout "display"

  def thirteen
    render "thirteen", locals: {view_object: view_object}
  rescue => e
    render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
  end

  def mira
    @refresh = params[:refresh] != "false"

    begin
      render("mira", locals: {view_object: view_object}, layout: params[:layout] != "false")
    rescue => e
      render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
    end
  end

  private

  def view_object
    if HomeAssistantApi.new.demo_mode?
      DisplayContent.new.call(calendar_feed: Demo::CalendarFeed.new, home_assistant_calendar_api: Demo::HomeAssistantCalendarApi.new)
    else
      DisplayContent.new.call
    end
  end
end
# :nocov:

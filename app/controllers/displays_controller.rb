class DisplaysController < ApplicationController
  layout "display"

  def thirteen
    # :nocov:
    begin
      render "thirteen", locals: {view_object: DisplayContent.new.call}
    rescue => e
      render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
    end
    # :nocov:
  end

  def mira
    @refresh = true

    # :nocov:
    begin
      Rack::MiniProfiler.authorize_request if params[:pp]

      render "mira", locals: {view_object: DisplayContent.new.call}
    rescue => e
      render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
    end
    # :nocov:
  end
end

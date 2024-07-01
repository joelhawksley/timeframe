# :nocov:
class DisplaysController < ApplicationController
  layout "display"

  def thirteen
    @refresh = params[:refresh] || ""

    render "thirteen", locals: {view_object: DisplayContent.new.call}
  rescue => e
    render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
  end

  def mira
    @refresh = params[:refresh] || 2

    begin
      render "mira", locals: {view_object: DisplayContent.new.call}
    rescue => e
      render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
    end
  end
end
# :nocov:

# :nocov:
class DisplaysController < ApplicationController
  layout "display"

  def thirteen
    render "thirteen", locals: {view_object: DisplayContent.new.call}
  rescue => e
    render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
  end

  def mira
    @refresh = params[:refresh] != "false"

    begin
      render("mira", locals: {view_object: DisplayContent.new.call}, layout: params[:layout] != "false")
    rescue => e
      render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
    end
  end
end
# :nocov:

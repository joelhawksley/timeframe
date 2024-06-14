class DisplaysController < ApplicationController
  layout "display"

  def thirteen
    # :nocov:

    render "thirteen", locals: {view_object: DisplayContent.new.call}
  rescue => e
    render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}

    # :nocov:
  end

  def mira
    @refresh = true

    # :nocov:
    begin
      render "mira", locals: {view_object: DisplayContent.new.call}
    rescue => e
      render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
    end
    # :nocov:
  end
end

class DisplaysController < ApplicationController
  layout "display"
  after_action { response.headers["X-Deploy-Time"] = DEPLOY_TIME.to_s }

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
    DisplayContent.new.call
  end
end

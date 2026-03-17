class DisplaysController < ApplicationController
  layout "display"
  after_action { response.headers["X-Deploy-Time"] = DEPLOY_TIME.to_s }

  def show
    @device = Device.find_by!(name: params[:name])
    template = Device::SUPPORTED_MODELS.dig(@device.model, :template)

    if template == "mira"
      @refresh = params[:refresh] != "false"
    end

    render template, locals: {view_object: view_object}, layout: params[:layout] != "false"
  rescue ActiveRecord::RecordNotFound
    render plain: "Device not found", status: :not_found
  rescue => e
    render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
  end

  private

  def view_object
    DisplayContent.new.call
  end
end

class DisplaysController < ApplicationController
  layout "display"
  after_action { response.headers["X-Deploy-Time"] = DEPLOY_TIME.to_s }

  def show
    @device = Device.all.find { |d| d.slug == params[:name] }
    raise ActiveRecord::RecordNotFound unless @device

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

  def preview
    @device = Device.all.find { |d| d.slug == params[:name] }
    raise ActiveRecord::RecordNotFound unless @device

    @width = @device.display_width
    @height = @device.display_height
    @display_url = display_path(name: @device.slug)
    render layout: false
  rescue ActiveRecord::RecordNotFound
    render plain: "Device not found", status: :not_found
  end

  def screenshot
    @device = Device.all.find { |d| d.slug == params[:name] }
    raise ActiveRecord::RecordNotFound unless @device

    @device.refresh_screenshot!(request.base_url) if @device.cached_image.blank?
    image_data = Base64.strict_decode64(@device.reload.cached_image)

    send_data image_data, type: "image/png", disposition: "inline", filename: "#{@device.slug}.png?#{Time.now.to_i}"
  rescue ActiveRecord::RecordNotFound
    render plain: "Device not found", status: :not_found
  end

  private

  def view_object
    if @device.demo_mode_enabled?
      DemoDisplayContent.new.call
    else
      DisplayContent.new.call
    end
  end
end

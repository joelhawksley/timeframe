class DisplaysController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  before_action :authorize_display_access!
  layout "display"
  after_action { response.headers["X-Deploy-Time"] = DEPLOY_TIME.to_s }

  def show
    if @device.pending_confirmation?
      render "displays/confirmation", locals: {device: @device}, layout: params[:layout] != "false"
      return
    end

    template = Device::SUPPORTED_MODELS.dig(@device.model, :template)

    if template == "mira"
      @refresh = params[:refresh] != "false"
    end

    render template, locals: {view_object: view_object}, layout: params[:layout] != "false"
  rescue => e
    render "error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
  end

  def preview
    @width = @device.display_width
    @height = @device.display_height
    @display_url = account_display_path(account_id: params[:account_id], id: @device.id)
    render layout: false
  end

  def screenshot
    @device.refresh_screenshot!(request.base_url) if @device.cached_image.blank? || params[:force] == "true"
    image_data = Base64.strict_decode64(@device.reload.cached_image)

    send_data image_data, type: "image/png", disposition: "inline", filename: "#{@device.id}.png?#{Time.now.to_i}"
  end

  private

  def view_object
    if @device.demo_mode_enabled?
      DemoDisplayContent.new.call
    else
      config = TimeframeConfig.new
      weather_kit = if !config.home_assistant? && config.weatherkit? && @device.location
        WeatherKitApi.new(location: @device.location)
      end
      DisplayContent.new.call(weather_kit_api: weather_kit)
    end
  end

  def authorize_display_access!
    if params[:account_id]
      account = Account.find_by(id: params[:account_id])
      return render(plain: "Account not found", status: :not_found) unless account
      @device = account.devices.find_by(id: params[:id])
    elsif current_user
      @device = current_user.accounts.flat_map(&:devices).find { |d| d.id == params[:id].to_i }
    end

    return render(plain: "Device not found", status: :not_found) unless @device

    # Logged-in owner always has access
    return if current_user&.accounts&.exists?(id: @device.account&.id)

    render plain: "Not authorized", status: :unauthorized
  end
end

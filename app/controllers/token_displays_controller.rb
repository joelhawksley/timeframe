# frozen_string_literal: true

class TokenDisplaysController < ApplicationController
  skip_before_action :auto_sign_in_default_user!
  skip_before_action :authenticate_user!, raise: false
  before_action :authorize_via_tokens!
  layout "display"

  after_action do
    response.headers["X-Deploy-Time"] = DEPLOY_TIME.to_s
    response.headers["Referrer-Policy"] = "no-referrer"
  end

  def show
    if @device.pending_confirmation?
      render "displays/confirmation", locals: {device: @device}, layout: params[:layout] != "false"
      return
    end

    template = Device::SUPPORTED_MODELS.dig(@device.model, :template)

    if template == "mira"
      @refresh = params[:refresh] != "false"
    end

    render "displays/#{template}", locals: {view_object: view_object}, layout: params[:layout] != "false"
  rescue => e
    render "displays/error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
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

  def authorize_via_tokens!
    @device = Device.find_by(id: params[:id])

    unless @device&.visionect? && params[:key].present? &&
        ActiveSupport::SecurityUtils.secure_compare(@device.display_key, params[:key].to_s)
      render plain: "Not authorized", status: :unauthorized
    end
  end
end

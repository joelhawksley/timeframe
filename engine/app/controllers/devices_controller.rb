# frozen_string_literal: true

class DevicesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false, only: [:confirmation_image, :show, :screenshot]
  before_action :set_account_and_location, except: [:confirmation_image, :show, :screenshot]
  before_action :authorize_device_access!, only: [:show, :screenshot]
  layout "device", only: [:show]
  after_action(only: [:show, :screenshot]) { response.headers["X-Deploy-Time"] = DEPLOY_TIME.to_s }

  def show
    if @device.pending_confirmation?
      render "devices/confirmation", locals: {device: @device}, layout: params[:layout] != "false"
      return
    end

    @device.update_column(:last_connection_at, Time.current) if session[:device_session_token].present?

    template = @device.active_template

    if @device.realtime_display?
      @refresh = params[:refresh] != "false"
    end

    view_object = @device.device_content

    render "devices/#{template}", locals: {view_object: view_object}, layout: params[:layout] != "false"
  rescue => e
    render "devices/error", locals: {klass: e.class.to_s, message: e.message, backtrace: e.backtrace}
  end

  def screenshot
    @device.refresh_screenshot!(request.base_url) if @device.cached_image.blank? || params[:force] == "true"
    image_data = Base64.strict_decode64(@device.reload.cached_image)

    send_data image_data, type: "image/png", disposition: "inline", filename: "#{@device.id}.png?#{Time.now.to_i}"
  end

  def create
    model = params[:device_model]
    name = params[:device_name].to_s.strip

    if model == "visionect_13"
      @location.devices.create!(name: name, model: model)
      redirect_to root_path, notice: "Device \"#{name}\" added."
    else
      pairing_code = params[:pairing_code].to_s.strip
      pending_device = PendingDevice.find_active_by_code(pairing_code)

      unless pending_device
        return redirect_to root_path, alert: "Invalid or expired pairing code."
      end

      pending_device.claim!(location: @location, name: name, model: model)
      redirect_to root_path, notice: "Device \"#{name}\" paired successfully."
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path, alert: e.message
  end

  def update
    device = @location.devices.find(params[:id])
    device.update!(demo_mode_enabled: !device.demo_mode_enabled?)
    redirect_to root_path
  end

  def update_template
    device = @location.devices.find(params[:id])
    device.update!(display_template: params[:display_template])
    redirect_to root_path
  end

  def destroy
    device = @location.devices.find(params[:id])

    if params[:name_confirmation].to_s.downcase.strip == device.name.downcase.strip
      device.destroy
    end

    redirect_to root_path
  end

  def regenerate_tokens
    device = @location.devices.find(params[:id])

    if params[:name_confirmation].to_s.downcase.strip == device.name.downcase.strip
      device.regenerate_display_key!
    end

    redirect_to root_path
  end

  def repair
    device = @location.devices.find(params[:id])
    pairing_code = params[:pairing_code].to_s.strip
    pending_device = PendingDevice.find_active_by_code(pairing_code)

    unless pending_device
      return redirect_to root_path, alert: "Invalid or expired pairing code."
    end

    pending_device.update!(claimed_device: device)
    device.rotate_session_token!
    redirect_to root_path, notice: "\"#{device.name}\" re-paired successfully."
  end

  def confirmation_image
    device = Device.find(params[:id])

    unless device.pending_confirmation?
      return head :not_found
    end

    width = device.display_width
    height = device.display_height
    title_size = [width, height].min / 15
    code_size = [width, height].min / 6
    sub_size = [width, height].min / 20

    image = MiniMagick::Image.create(".png") do |f|
      MiniMagick.convert do |convert|
        convert.size "#{width}x#{height}"
        convert << "xc:white"
        convert.gravity "Center"
        convert.font "Helvetica"
        convert.pointsize title_size
        convert.annotate("+0-#{height / 6}", "Add this device to your")
        convert.annotate("+0-#{height / 10}", "Timeframe account:")
        convert.pointsize code_size
        convert.annotate("+0+#{height / 12}", device.confirmation_code)
        convert.pointsize sub_size
        convert.annotate("+0+#{height / 4}", "Enter this code at")
        convert.annotate("+0+#{height / 4 + sub_size + 10}", "your Timeframe dashboard")
        convert << f.path
      end
    end

    send_data image.to_blob, type: "image/png", disposition: "inline"
  end

  private

  def set_account_and_location
    @account = current_user.accounts.find(params[:account_id])
    @location = @account.locations.find(params[:location_id])
  end

  def authorize_device_access!
    if params[:account_id] && params[:location_id]
      account = Account.find_by(id: params[:account_id])
      return render(plain: "Account not found", status: :not_found) unless account
      location = account.locations.find_by(id: params[:location_id])
      return render(plain: "Location not found", status: :not_found) unless location
      @device = location.devices.find_by(id: params[:id])
    elsif current_user
      @device = current_user.accounts.flat_map(&:devices).find { |d| d.id == params[:id].to_i }
    end

    return render(plain: "Device not found", status: :not_found) unless @device

    return if current_user&.accounts&.exists?(id: @device.account&.id)

    if session[:device_session_token].present? && @device.session_token.present? &&
        ActiveSupport::SecurityUtils.secure_compare(@device.session_token, session[:device_session_token])
      return
    end

    render plain: "Not authorized", status: :unauthorized
  end
end

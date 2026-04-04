# frozen_string_literal: true

class DevicesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false, only: [:confirmation_image]
  before_action :set_account_and_location, except: [:confirmation_image]

  def create
    model = params[:device_model]
    name = params[:device_name].to_s.strip

    if model == "visionect_13"
      @location.devices.create!(name: name, model: model)
      redirect_to root_path, notice: "Device \"#{name}\" added."
    else
      pairing_code = params[:pairing_code].to_s.strip.upcase
      pending_device = PendingDevice.find_by(pairing_code: pairing_code)

      unless pending_device
        return redirect_to root_path, alert: "Invalid pairing code."
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
end

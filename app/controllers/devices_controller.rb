# frozen_string_literal: true

class DevicesController < ApplicationController
  before_action :authenticate_user!

  def show
    current_device = current_user.devices.find(params[:id])

    respond_to do |format|
      format.html do
        render(html: current_device.html.html_safe, layout: false)
      end
      format.png do
        send_data current_device.current_image, type: "image/png", disposition: "inline"
      end
    end
  end

  def create
    current_user.devices.create(device_params)

    redirect_to(root_path, flash: {notice: "Device created."})
  end

  private

  def device_params
    params.require(:device).permit(:uuid, :template)
  end
end

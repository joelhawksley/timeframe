# frozen_string_literal: true

class DevicesController < ApplicationController
  def index
    @devices = Device.order(:name)
  end

  def create
    @device = Device.new(device_params)

    if @device.save
      redirect_to root_path
    else
      @devices = Device.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    device = Device.find(params[:id])

    if params[:name_confirmation].to_s.downcase.strip == device.name.downcase.strip
      device.destroy
    end

    redirect_to root_path
  end

  private

  def device_params
    params.require(:device).permit(:name, :model)
  end
end

class DevicesController < ApplicationController
  before_action :authenticate_user!

  def show
    render locals: { current_device: current_user.devices.find(params[:id]) }
  end
end

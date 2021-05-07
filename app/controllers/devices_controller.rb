class DevicesController < ApplicationController
  before_action :authenticate_user!

  def show
    current_device = current_user.devices.find(params[:id])

    respond_to do |format|
      format.html do
        render "image_templates/#{current_device.template}", locals: { view_object: current_device.view_object }, layout: false
      end
      format.png do
        send_data current_device.current_image, :type => 'image/png', :disposition => 'inline'
      end
    end
  end
end

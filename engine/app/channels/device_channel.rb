# frozen_string_literal: true

class DeviceChannel < ApplicationCable::Channel
  def subscribed
    device = Device.find_by(id: params[:device_id])
    return reject unless device

    if device.accessible_by?(user: current_user, device: current_device)
      stream_for device
    else
      reject
    end
  end
end

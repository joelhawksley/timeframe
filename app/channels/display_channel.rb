# frozen_string_literal: true

class DisplayChannel < ApplicationCable::Channel
  def subscribed
    device = Device.find_by(id: params[:device_id])
    return reject unless device

    # Allow if logged-in user owns the device
    if current_user&.accounts&.exists?(id: device.account&.id)
      return stream_for device
    end

    # Allow if device session matches
    if current_device&.id == device.id
      return stream_for device
    end

    reject
  end
end

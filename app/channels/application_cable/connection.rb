# frozen_string_literal: true

class ApplicationCable::Connection < ActionCable::Connection::Base
  identified_by :current_user, :current_device

  def connect
    self.current_user = env["warden"].user
    self.current_device = find_device_by_session

    reject_unauthorized_connection unless current_user || current_device
  end

  private

  def find_device_by_session
    token = request.session[:device_session_token]
    device_id = request.session[:claimed_device_id]
    return unless token.present? && device_id.present?

    device = Device.find_by(id: device_id)
    return unless device&.session_token.present?

    if ActiveSupport::SecurityUtils.secure_compare(device.session_token, token)
      device
    end
  end
end

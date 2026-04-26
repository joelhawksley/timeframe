# frozen_string_literal: true

class ApplicationCable::Connection < ActionCable::Connection::Base
  identified_by :current_user, :current_device

  def connect
    self.current_user = env["warden"]&.user(:user)
    self.current_device = find_device_by_session

    reject_unauthorized_connection unless current_user || current_device
  end

  private

  def find_device_by_session
    Device.authenticate_session(
      request.session[:claimed_device_id],
      request.session[:device_session_token]
    )
  end
end

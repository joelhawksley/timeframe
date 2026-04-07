# frozen_string_literal: true

class SetupController < ApplicationController
  skip_before_action :auto_sign_in_default_user!
  skip_before_action :authenticate_user!

  def index
    redirect_to root_path if warden.authenticated?(:user)

    # If device already claimed, redirect to its display URL with device session
    if session[:claimed_device_id] && session[:device_session_token]
      @device = Device.find_by(id: session[:claimed_device_id])
      if @device
        return redirect_to account_location_device_path(@device.account, @device.location, @device)
      else
        session.delete(:claimed_device_id)
        session.delete(:device_session_token)
      end
    end

    @pending_device = if session[:pending_device_id]
      PendingDevice.find_by(id: session[:pending_device_id])
    end

    # If pending device was claimed, create device session and redirect
    if @pending_device&.claimed?
      @device = @pending_device.claimed_device
      token = @device.rotate_session_token!
      session[:claimed_device_id] = @device.id
      session[:device_session_token] = token
      session.delete(:pending_device_id)
      @pending_device.destroy!

      return redirect_to account_location_device_path(@device.account, @device.location, @device)
    end

    unless @pending_device
      @pending_device = PendingDevice.create!
      session[:pending_device_id] = @pending_device.id
    end
  end
end

# frozen_string_literal: true

class SetupController < ApplicationController
  skip_before_action :auto_sign_in_default_user!
  skip_before_action :authenticate_user!

  def index
    redirect_to root_path if warden.authenticated?(:user)

    # If device already claimed, keep showing its display
    if session[:claimed_device_id]
      @device = Device.find_by(id: session[:claimed_device_id])
      if @device
        template = Device::SUPPORTED_MODELS.dig(@device.model, :template)
        view_data = DisplayContent.new.call
        return render "displays/#{template}", locals: {view_object: view_data}, layout: "display"
      else
        session.delete(:claimed_device_id)
      end
    end

    @pending_device = if session[:pending_device_id]
      PendingDevice.find_by(id: session[:pending_device_id])
    end

    # If pending device was claimed, switch to display mode
    if @pending_device&.claimed?
      @device = @pending_device.claimed_device
      session[:claimed_device_id] = @device.id
      session.delete(:pending_device_id)
      @pending_device.destroy!

      template = Device::SUPPORTED_MODELS.dig(@device.model, :template)
      view_data = DisplayContent.new.call
      return render "displays/#{template}", locals: {view_object: view_data}, layout: "display"
    end

    unless @pending_device
      @pending_device = PendingDevice.create!
      session[:pending_device_id] = @pending_device.id
    end
  end
end

# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @accounts = current_user.accounts.includes(locations: :devices, calendars: :calendar_events, google_accounts: :calendars)

    render "dashboard/multi_tenant"
  end

  def claim_device
    pairing_code = params[:pairing_code].to_s.strip.upcase
    pending_device = PendingDevice.find_active_by_code(pairing_code)

    unless pending_device
      return redirect_to root_path, alert: "Invalid or expired pairing code."
    end

    name = params[:device_name].to_s.strip
    model = params[:device_model]
    location_id = params[:location_id]

    unless name.present? && Device::SUPPORTED_MODELS.key?(model) && location_id.present?
      return redirect_to root_path, alert: "Name, model, and location are required."
    end

    location = current_user.accounts.flat_map(&:locations).find { |l| l.id == location_id.to_i }
    unless location
      return redirect_to root_path, alert: "Location not found."
    end

    pending_device.claim!(location: location, name: name, model: model)
    redirect_to root_path, notice: "Device \"#{name}\" paired successfully."
  end
end

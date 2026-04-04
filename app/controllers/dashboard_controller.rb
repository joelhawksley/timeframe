# frozen_string_literal: true

class DashboardController < ApplicationController
  HA_DOMAIN_CHECKS = [
    {name: "States", healthy: :states_healthy?, last_fetched_at: :states_last_fetched_at, icon: "mdi-list-status"},
    {name: "Calendars", healthy: :calendars_healthy?, last_fetched_at: :calendars_last_fetched_at, icon: "mdi-calendar"},
    {name: "Config", healthy: :config_healthy?, last_fetched_at: :config_last_fetched_at, icon: "mdi-cog"},
    {name: "Weather", healthy: :weather_healthy?, last_fetched_at: :weather_last_fetched_at, icon: "mdi-weather-partly-cloudy"}
  ].freeze

  def index
    @accounts = current_user.accounts.includes(locations: :devices, calendars: :calendar_events, google_accounts: :calendars)
    @multi_tenant = Timeframe::Application.multi_tenant?

    unless @multi_tenant
      @account = @accounts.first
      @location = @account&.locations&.first
      @devices = @location&.devices&.order(:name) || Device.none
    end

    render @multi_tenant ? "dashboard/multi_tenant" : "dashboard/single_tenant"
  end

  def claim_device
    pairing_code = params[:pairing_code].to_s.strip.upcase
    pending_device = PendingDevice.find_by(pairing_code: pairing_code)

    unless pending_device
      return redirect_to root_path, alert: "Invalid pairing code."
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

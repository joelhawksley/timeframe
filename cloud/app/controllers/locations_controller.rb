# frozen_string_literal: true

class LocationsController < ApplicationController
  def create
    account = current_user.accounts.find(params[:account_id])

    result = Geocoder.search(params[:location][:address]).first

    unless result
      return redirect_to root_path, alert: "Could not find that address. Please try again."
    end

    location = account.locations.new(
      name: params[:location][:name],
      latitude: result.latitude,
      longitude: result.longitude,
      time_zone: time_zone_for(result.latitude, result.longitude)
    )

    if location.save
      redirect_to root_path, notice: "Location \"#{location.name}\" added."
    else
      redirect_to root_path, alert: location.errors.full_messages.join(", ")
    end
  end

  def destroy
    account = current_user.accounts.find(params[:account_id])
    location = account.locations.find(params[:id])

    if location.devices.any?
      redirect_to root_path, alert: "Delete all devices before deleting this location."
    else
      location.destroy
      redirect_to root_path, notice: "Location \"#{location.name}\" deleted."
    end
  end

  private

  def time_zone_for(lat, lng)
    tz = TimezoneFinder.create.timezone_at(lat: lat.to_f, lng: lng.to_f)
    tz || "America/Chicago"
  rescue
    "America/Chicago"
  end
end

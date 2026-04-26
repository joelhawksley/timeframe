# frozen_string_literal: true

class LocationsController < ApplicationController
  def create
    account = current_user.accounts.find(params[:account_id])

    location = account.locations.new(
      name: params[:location][:name],
      latitude: params[:location][:latitude],
      longitude: params[:location][:longitude],
      time_zone: params[:location][:time_zone] || "America/Chicago"
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
end

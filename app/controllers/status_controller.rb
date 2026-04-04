# frozen_string_literal: true

class StatusController < ApplicationController
  def index
    @api = HomeAssistantApi.new
    @statuses = DashboardController::HA_DOMAIN_CHECKS.map do |check|
      {
        name: check[:name],
        icon: check[:icon],
        healthy: @api.send(check[:healthy]),
        last_fetched_at: @api.send(check[:last_fetched_at])&.iso8601
      }
    end
  end
end

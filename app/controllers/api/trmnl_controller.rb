# frozen_string_literal: true

module Api
  class TrmnlController < ActionController::API
    before_action :authenticate_device!, only: [:display, :log]
    after_action :log_response_payload

    # GET /api/setup
    # Auto-provisions a new TRMNL device by MAC address.
    # Returns existing device info if MAC is already registered.
    def setup
      Rails.logger.info("[API Setup] params=#{params.to_unsafe_h} headers=#{request.headers.env.select { |k, _| k.start_with?("HTTP_") }}")

      mac_address = request.headers["ID"]
      return head :bad_request if mac_address.blank?

      device = Device.find_by(mac_address: mac_address) || provision_device!(mac_address)

      render json: {
        api_key: device.api_key,
        friendly_id: device.friendly_id,
        message: "Welcome to Timeframe"
      }
    end

    # GET /api/display
    # Returns the current display image for the device.
    def display
      Rails.logger.info("[API Display] params=#{params.to_unsafe_h} headers=#{request.headers.env.select { |k, _| k.start_with?("HTTP_") }}")

      @device.refresh_screenshot!(request.base_url) if @device.cached_image.blank? || params[:force].present?

      render json: {
        filename: "display-#{@device.cached_image_at}.png",
        image_url: "#{request.base_url}/accounts/me/displays/#{@device.slug}/screenshot",
        image_url_timeout: 0,
        refresh_rate: 900,
        reset_firmware: false,
        special_function: "sleep",
        update_firmware: false
      }
    end

    # POST /api/log
    # Accepts device log data. No-op for now.
    def log
      Rails.logger.info("[API Log] params=#{params.to_unsafe_h} headers=#{request.headers.env.select { |k, _| k.start_with?("HTTP_") }}")
      head :no_content
    end

    private

    def log_response_payload
      Rails.logger.info("[API Response] action=#{action_name} status=#{response.status} body=#{response.body}")
    end

    def authenticate_device!
      mac_address = request.headers["ID"]
      return head :unauthorized if mac_address.blank?

      @device = Device.find_by(mac_address: mac_address)

      if @device.nil?
        @device = provision_device!(mac_address)
        return
      end

      access_token = request.env["HTTP_ACCESS_TOKEN"].presence || request.env["ACCESS_TOKEN"].presence
      return unless access_token
      head :unauthorized unless @device.authenticate_api_key(access_token)
    end

    def provision_device!(mac_address)
      friendly_id = SecureRandom.alphanumeric(6).upcase
      Device.create!(
        name: "TRMNL #{friendly_id}",
        model: "trmnl_og",
        mac_address: mac_address
      )
    end
  end
end

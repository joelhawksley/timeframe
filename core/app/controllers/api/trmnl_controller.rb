# frozen_string_literal: true

module Api
  class TrmnlController < ActionController::API
    include Rails.application.routes.url_helpers

    before_action :authenticate_device!
    skip_before_action :authenticate_device!, only: [:setup]
    after_action :log_response_status

    # GET /api/setup
    def setup
      Rails.logger.info("[API Setup] mac=#{request.headers["ID"]}")

      mac_address = request.headers["ID"]
      return head :bad_request if mac_address.blank?

      device = Device.find_by(mac_address: mac_address)
      if device
        render json: {
          api_key: device.api_key,
          friendly_id: device.friendly_id,
          message: "Welcome to Timeframe"
        }
        return
      end

      pending = PendingDevice.find_or_create_by!(mac_address: mac_address) do |pd|
        pd.api_key = SecureRandom.hex(16)
        pd.friendly_id = SecureRandom.alphanumeric(6).upcase
      end

      render json: {
        friendly_id: pending.friendly_id,
        pairing_code: pending.pairing_code,
        message: "Pending pairing"
      }
    end

    # GET /api/display
    def display
      Rails.logger.info("[API Display] mac=#{request.headers["ID"]} device_id=#{@device&.id}")

      if @device.pending_confirmation?
        render json: {
          filename: "confirmation-#{@device.id}.png",
          image_url: confirmation_image_account_location_device_url(@device.account, @device.location, @device, host: request.base_url),
          image_url_timeout: 0,
          refresh_rate: 30,
          reset_firmware: false,
          special_function: "sleep",
          update_firmware: false
        }
        return
      end

      @device.refresh_screenshot!(request.base_url) if @device.cached_image.blank? || params[:force].present?

      render json: {
        filename: "display-#{@device.cached_image_at}.png",
        image_url: @device.signed_screenshot_url(host: request.base_url),
        image_url_timeout: 0,
        refresh_rate: 900,
        reset_firmware: false,
        special_function: "sleep",
        update_firmware: false
      }
    end

    # POST /api/log
    def log
      Rails.logger.info("[API Log] mac=#{request.headers["ID"]}")
      head :no_content
    end

    private

    def log_response_status
      Rails.logger.info("[API Response] action=#{action_name} status=#{response.status}")
    end

    def authenticate_device!
      mac_address = request.headers["ID"]
      return head :unauthorized if mac_address.blank?

      @device = Device.find_by(mac_address: mac_address)
      return head :unauthorized if @device.nil?

      access_token = request.env["HTTP_ACCESS_TOKEN"].presence || request.env["ACCESS_TOKEN"].presence
      return unless access_token
      head :unauthorized unless @device.authenticate_api_key(access_token)
    end
  end
end

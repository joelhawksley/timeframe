# frozen_string_literal: true

class SignedScreenshotsController < ApplicationController
  skip_before_action :auto_sign_in_default_user!
  skip_before_action :authenticate_user!, raise: false

  def show
    device = GlobalID::Locator.locate_signed(params[:sgid], for: "screenshot")

    unless device
      return render plain: "Not authorized", status: :unauthorized
    end

    device.refresh_screenshot!(request.base_url) if device.cached_image.blank? || params[:force] == "true"
    image_data = Base64.strict_decode64(device.reload.cached_image)

    send_data image_data, type: "image/png", disposition: "inline", filename: "#{device.id}.png?#{Time.now.to_i}"
  end
end

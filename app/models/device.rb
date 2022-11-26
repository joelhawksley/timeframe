# frozen_string_literal: true

require "visionect"
require "slim/include"

class Device < ApplicationRecord
  belongs_to :user

  TEMPLATES = {
    "13_calendar_weather": {
      title: "13\" Place & Play",
      width: 1200,
      height: 1600
    },
    mira_pro_vert: {
      title: "4k Boox Mira Pro, Vertical",
      width: 1800,
      height: 3200,
    }
  }

  def battery_level
    return 100 unless status.is_a?(Hash)

    status.dig("Status", "Battery")&.to_i || 100
  end

  def error_messages
    # Only include weather error messages for weather display
    out = user.alerts(template.to_sym == :weather)

    out << "Battery level low. Please plug me in overnight!" if battery_level < 10

    out
  end

  def view_object
    out = user.render_json_payload
    out[:error_messages] = error_messages
    out[:battery_level] = battery_level

    out
  end

  def width
    TEMPLATES[template.to_sym][:width]
  end

  def height
    TEMPLATES[template.to_sym][:height]
  end

  def html
    Slim::Template.new(
      Rails.root.join("app", "views", "image_templates", "#{template}.html.slim")
    ).render(
      Object.new,
      view_object: view_object,
      device: self
    )
  end

  def render_image
    imgkit_params = {
      encoding: "UTF-8",
      quality: 100,
      width: width,
      height: height
    }

    image = IMGKit.new(html, imgkit_params)

    update(current_image: image.to_img(:png))
  end

  def push
    return unless ENV["VISIONECT_HOST"].present?

    Visionect::Client.new.update_backend(uuids: [uuid], binary_png: current_image)
  end

  def fetch
    return unless ENV["VISIONECT_HOST"].present?

    update(status: JSON.parse(Visionect::Client.new.get_device(uuid: uuid).body))
  rescue
    puts "device not found"
  end
end

require 'visionect'

class Device < ApplicationRecord
  belongs_to :user

  def battery_level
    return 100 unless status.is_a?(Hash)

    status.dig("Status", "Battery")&.to_i || 100
  end

  def error_messages
    out = user.alerts

    if battery_level < 10
      out << "Battery level low. Please plug me in overnight!"
    end

    out
  end

  def render_image
    imgkit_params = {
      encoding: 'UTF-8',
      quality: 100,
      width: width,
      height: height
    }

    view_object = user.render_json_payload
    view_object[:error_messages] = error_messages
    view_object[:battery_level] = battery_level

    html =
      Slim::Template.new(
        Rails.root.join("app", "views", "image_templates", "#{template}.html.slim")
      ).render(
        Object.new,
        view_object: view_object,
      )

    image = IMGKit.new(html, imgkit_params)
    image.stylesheets << Rails.root.join("app", "assets", "image_templates", "font-awesome.css")
    image.stylesheets << Rails.root.join("app", "assets", "image_templates", "weathericons.css")
    image.stylesheets << Rails.root.join("app", "assets", "image_templates", "fonts.css")
    image.stylesheets << Rails.root.join("app", "assets", "image_templates", "styles.css")

    update(current_image: image.to_img(:png))
  end

  def push
    Visionect::Client.new.update_backend(uuids: [uuid], binary_png: current_image)
  end

  def fetch
    update(status: JSON.parse(Visionect::Client.new.get_device(uuid: uuid).body))
  end
end

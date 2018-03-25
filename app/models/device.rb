require 'visionect'

class Device < ApplicationRecord
  belongs_to :user

  def render_image
    imgkit_params = {
      encoding: 'UTF-8',
      quality: 100,
      width: width,
      height: height
    }

    html = Slim::Template.new(Rails.root.join("app", "views", "image_templates", "#{template}.html.slim")).render(Object.new, view_object: user.render_json_payload)

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
end

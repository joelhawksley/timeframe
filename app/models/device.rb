require 'net/http/post/multipart'

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
    image.stylesheets << Rails.root.join("app", "assets", "stylesheets", "image_templates", "font-awesome.css")
    image.stylesheets << Rails.root.join("app", "assets", "stylesheets", "image_templates", "fonts.css")
    image.stylesheets << Rails.root.join("app", "assets", "stylesheets", "image_templates", "styles.css")

    update(current_image: image.to_img(:png))
  end

  def push
    host = 'visionect.hawksley.org'
    api_key = '6451284aeb53ca4b'
    api_secret = '1dXu3/uw00ep0T1zacuHkByEAruP7Llyt7YakU11b/0'

    boundary = "#{rand(10000000000000000000)}"
    date = Time.new.httpdate
    url = "http://#{host}:8081/backend/#{uuid}"
    string = "PUT\n\nmultipart/form-data; boundary=#{boundary}\n#{date}\n/backend/#{uuid}"
    auth_value = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), api_secret, string)).strip()

    StringIO.open(current_image) do |png|
      req = Net::HTTP::Put::Multipart.new(
        "/backend/#{uuid}",
        { image: UploadIO.new(png, "image/png", "image.png") },
        { "Date" => date, "Authorization" => "#{api_key}:#{auth_value}" },
        boundary
      )
      http = Net::HTTP.new(host, 8081)
      http.request(req)
    end
  end
end

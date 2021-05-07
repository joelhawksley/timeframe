# frozen_string_literal: true

IMGKit.configure do |config|
  config.wkhtmltoimage = Rails.root.join('bin', 'wkhtmltoimage').to_s if ENV['RACK_ENV'] == 'production'
end

# frozen_string_literal: true

namespace :fetch do
  task all: :environment do
    GoogleAccount.all.each(&:refresh!)
    User.all.each do |user|
      user.fetch
      user.devices.each do |device|
        device.render_image
        device.push
        device.fetch
      end
    end
  end
end

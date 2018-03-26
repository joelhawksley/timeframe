namespace :fetch do
  task all: :environment do
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

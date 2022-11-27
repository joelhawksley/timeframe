# frozen_string_literal: true

require "visionect"
class Device < ApplicationRecord
  def fetch
    return unless ENV["VISIONECT_HOST"].present?

    update(status: JSON.parse(Visionect::Client.new.get_device(uuid: uuid).body))
  rescue
    puts "device not found"
  end
end

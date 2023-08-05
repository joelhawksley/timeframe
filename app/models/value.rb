# frozen_string_literal: true

class Value < ApplicationRecord
  def self.weather
    find_or_create_by(key: "weather").value
  end
end

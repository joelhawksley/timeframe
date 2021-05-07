# frozen_string_literal: true

class AddWeatherToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :weather, :jsonb
  end
end

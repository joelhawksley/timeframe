# frozen_string_literal: true

class AddDemoModeEnabledToDevices < ActiveRecord::Migration[8.0]
  def change
    add_column :devices, :demo_mode_enabled, :boolean, default: false, null: false
  end
end

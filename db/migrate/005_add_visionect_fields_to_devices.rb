# frozen_string_literal: true

class AddVisionectFieldsToDevices < ActiveRecord::Migration[8.1]
  def change
    add_column :devices, :visionect_serial, :string
    add_column :devices, :battery_level, :float
    add_column :devices, :rssi, :integer
    add_column :devices, :temperature, :float
    add_column :devices, :firmware_version, :string
    add_column :devices, :last_connection_at, :datetime

    add_index :devices, :visionect_serial, unique: true
  end
end

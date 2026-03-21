# frozen_string_literal: true

class AddTrmnlFieldsToDevices < ActiveRecord::Migration[8.0]
  def change
    add_column :devices, :mac_address, :string
    add_column :devices, :api_key, :string
    add_column :devices, :friendly_id, :string

    add_index :devices, :mac_address, unique: true
    add_index :devices, :api_key, unique: true
  end
end

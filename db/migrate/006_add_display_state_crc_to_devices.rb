# frozen_string_literal: true

class AddDisplayStateCrcToDevices < ActiveRecord::Migration[8.1]
  def change
    add_column :devices, :display_state_crc, :integer, limit: 8
  end
end

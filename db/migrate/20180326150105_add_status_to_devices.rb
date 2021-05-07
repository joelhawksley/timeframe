# frozen_string_literal: true

class AddStatusToDevices < ActiveRecord::Migration[5.1]
  def change
    add_column :devices, :status, :jsonb, null: false, default: '{}'
  end
end

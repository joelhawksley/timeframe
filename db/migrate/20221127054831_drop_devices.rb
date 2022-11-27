class DropDevices < ActiveRecord::Migration[7.0]
  def change
    drop_table :devices
  end
end

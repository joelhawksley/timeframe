class CleanupDevices < ActiveRecord::Migration[6.1]
  def change
    remove_column :devices, :width
    remove_column :devices, :height
  end
end

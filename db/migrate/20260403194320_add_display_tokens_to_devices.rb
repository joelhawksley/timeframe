class AddDisplayTokensToDevices < ActiveRecord::Migration[8.1]
  def change
    add_column :devices, :display_key, :text

    add_index :devices, :display_key, unique: true

    reversible do |dir|
      dir.up do
        Device.find_each do |device|
          device.update_columns(
            display_key: SecureRandom.alphanumeric(24)
          )
        end
      end
    end
  end
end

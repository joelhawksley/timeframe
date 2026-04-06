class AddSessionTokenToDevices < ActiveRecord::Migration[8.1]
  def change
    add_column :devices, :session_token, :text
    add_index :devices, :session_token, unique: true
  end
end

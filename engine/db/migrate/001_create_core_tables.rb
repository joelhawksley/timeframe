# frozen_string_literal: true

class CreateCoreTables < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :accounts do |t|
      t.text :name, null: false
      t.timestamps
    end

    create_table :users do |t|
      t.text :email, null: false
      t.text :magic_link_nonce
      t.datetime :remember_created_at
      t.text :remember_token
      t.timestamps
      t.index :email, unique: true
    end

    create_table :account_users do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
      t.index [:account_id, :user_id], unique: true
    end

    create_table :locations do |t|
      t.references :account, null: false, foreign_key: true
      t.text :name, null: false
      t.text :latitude, null: false
      t.text :longitude, null: false
      t.string :time_zone, null: false
      t.timestamps
    end

    create_table :devices do |t|
      t.text :api_key
      t.float :battery_level
      t.text :cached_image
      t.datetime :cached_image_at
      t.string :confirmation_code
      t.datetime :confirmed_at
      t.boolean :demo_mode_enabled, default: false, null: false
      t.text :display_key
      t.bigint :display_state_crc
      t.string :firmware_version
      t.string :friendly_id
      t.datetime :last_connection_at
      t.references :location, foreign_key: true
      t.text :mac_address
      t.string :model, null: false
      t.string :name, null: false
      t.integer :rssi
      t.text :session_token
      t.float :temperature
      t.text :visionect_serial
      t.timestamps
      t.index :api_key, unique: true
      t.index :confirmation_code, unique: true
      t.index :display_key, unique: true
      t.index :mac_address, unique: true
      t.index :session_token, unique: true
      t.index :visionect_serial, unique: true
    end

    create_table :pending_devices do |t|
      t.text :api_key
      t.references :claimed_device, foreign_key: {to_table: :devices}
      t.string :friendly_id
      t.text :mac_address
      t.text :pairing_code, null: false
      t.timestamps
      t.index :mac_address, unique: true
      t.index :pairing_code, unique: true
    end
  end
end

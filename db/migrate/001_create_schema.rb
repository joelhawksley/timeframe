# frozen_string_literal: true

class CreateSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.text :name, null: false
      t.timestamps
    end

    create_table :users do |t|
      t.text :email, null: false
      t.text :remember_token
      t.datetime :remember_created_at
      t.text :magic_link_nonce
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
      t.string :name, null: false
      t.string :model, null: false
      t.boolean :demo_mode_enabled, default: false, null: false
      t.text :mac_address
      t.text :api_key
      t.string :friendly_id
      t.text :cached_image
      t.datetime :cached_image_at
      t.text :visionect_serial
      t.float :battery_level
      t.integer :rssi
      t.float :temperature
      t.string :firmware_version
      t.datetime :last_connection_at
      t.bigint :display_state_crc
      t.references :location, foreign_key: true
      t.string :confirmation_code
      t.datetime :confirmed_at
      t.timestamps
      t.index :mac_address, unique: true
      t.index :api_key, unique: true
      t.index :visionect_serial, unique: true
      t.index :confirmation_code, unique: true
    end

    create_table :google_accounts do |t|
      t.references :account, null: false, foreign_key: true
      t.text :google_uid, null: false
      t.text :email, null: false
      t.text :access_token, null: false
      t.text :refresh_token, null: false
      t.datetime :token_expires_at
      t.timestamps
      t.index [:account_id, :google_uid], unique: true
    end

    create_table :calendars do |t|
      t.references :account, null: false, foreign_key: true
      t.references :google_account, foreign_key: true
      t.string :name, null: false
      t.string :source_type, null: false
      t.string :external_id
      t.string :url
      t.datetime :last_synced_at
      t.string :webhook_channel_id
      t.string :webhook_resource_id
      t.datetime :webhook_expires_at
      t.timestamps
      t.index [:google_account_id, :external_id], unique: true
      t.index [:account_id, :source_type, :url], unique: true
    end

    create_table :calendar_events do |t|
      t.references :calendar, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :title
      t.text :description
      t.string :location
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :start_timezone
      t.string :end_timezone
      t.timestamps
      t.index [:calendar_id, :external_id], unique: true
      t.index :starts_at
      t.index :ends_at
    end

    create_table :audit_logs do |t|
      t.references :user, foreign_key: true
      t.string :event_type, null: false
      t.string :subject_type, null: false
      t.bigint :subject_id, null: false
      t.string :result_type
      t.json :metadata
      t.timestamps
      t.index :event_type
      t.index :created_at
      t.index [:subject_type, :subject_id], name: "index_audit_logs_on_subject"
    end

    create_table :pending_devices do |t|
      t.text :pairing_code, null: false
      t.text :mac_address
      t.string :friendly_id
      t.text :api_key
      t.references :claimed_device, foreign_key: {to_table: :devices}
      t.timestamps
      t.index :pairing_code, unique: true
      t.index :mac_address, unique: true
    end
  end
end

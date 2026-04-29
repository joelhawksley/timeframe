# frozen_string_literal: true

class CreateCoreTables < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :accounts do |t|
      t.text :name, null: false
      t.string :precipitation_unit, default: "in", null: false
      t.string :speed_unit, default: "mph", null: false
      t.string :temperature_unit, default: "F", null: false
      t.timestamps
    end

    create_table :users do |t|
      t.text :email, null: false
      t.boolean :is_admin, default: false, null: false
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
      t.string :display_template, default: "default", null: false
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

    create_table :google_accounts do |t|
      t.text :access_token, null: false
      t.references :account, null: false, foreign_key: true
      t.text :email, null: false
      t.text :google_uid, null: false
      t.text :refresh_token, null: false
      t.datetime :token_expires_at
      t.timestamps
      t.index [:account_id, :google_uid], unique: true
    end

    create_table :calendars do |t|
      t.references :account, null: false, foreign_key: true
      t.datetime :disabled_at
      t.string :external_id
      t.references :google_account, foreign_key: true
      t.string :icon
      t.datetime :last_synced_at
      t.string :name, null: false
      t.string :source_type, null: false
      t.string :url
      t.string :webhook_channel_id
      t.datetime :webhook_expires_at
      t.string :webhook_resource_id
      t.timestamps
      t.index [:account_id, :source_type, :url], unique: true
      t.index [:google_account_id, :external_id], unique: true
    end

    create_table :calendar_events do |t|
      t.string :attachment_content_type
      t.text :attachment_data
      t.references :calendar, null: false, foreign_key: true
      t.text :description
      t.string :end_timezone
      t.datetime :ends_at, null: false
      t.string :external_id, null: false
      t.string :location
      t.string :start_timezone
      t.datetime :starts_at, null: false
      t.string :title
      t.timestamps
      t.index [:calendar_id, :external_id], unique: true
      t.index :ends_at
      t.index :starts_at
    end

    create_table :audit_logs do |t|
      t.string :event_type, null: false
      t.json :metadata
      t.string :result_type
      t.references :subject, polymorphic: true, null: false
      t.references :user, foreign_key: true
      t.timestamps
      t.index :created_at
      t.index :event_type
    end

    create_table :weather_syncs do |t|
      t.references :location, null: false, foreign_key: true
      t.jsonb :response_data, null: false
      t.datetime :fetched_at, null: false
      t.timestamps
      t.index [:location_id, :fetched_at]
    end

    create_table :good_jobs, id: :uuid do |t|
      t.text :queue_name
      t.integer :priority
      t.jsonb :serialized_params
      t.datetime :scheduled_at
      t.datetime :performed_at
      t.datetime :finished_at
      t.text :error
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.uuid :active_job_id
      t.text :concurrency_key
      t.text :cron_key
      t.uuid :retried_good_job_id
      t.datetime :cron_at
      t.uuid :batch_id
      t.uuid :batch_callback_id
      t.boolean :is_discrete
      t.integer :executions_count
      t.text :job_class
      t.integer :error_event, limit: 2
      t.text :labels, array: true
      t.uuid :locked_by_id
      t.datetime :locked_at
    end

    add_index :good_jobs, :scheduled_at, where: "(finished_at IS NULL)", name: :index_good_jobs_on_scheduled_at
    add_index :good_jobs, [:queue_name, :scheduled_at], where: "(finished_at IS NULL)", name: :index_good_jobs_on_queue_name_scheduled_at
    add_index :good_jobs, :active_job_id, name: :index_good_jobs_on_active_job_id
    add_index :good_jobs, :cron_key, name: :index_good_jobs_on_cron_key

    create_table :good_job_processes, id: :uuid do |t|
      t.jsonb :state
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.integer :lock_type, limit: 2
    end

    create_table :good_job_settings, id: :uuid do |t|
      t.text :key
      t.jsonb :value
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :good_job_settings, :key, unique: true

    create_table :good_job_batches, id: :uuid do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.text :description
      t.jsonb :serialized_properties
      t.text :on_finish
      t.text :on_success
      t.text :on_discard
      t.text :callback_queue_name
      t.integer :callback_priority
      t.datetime :enqueued_at
      t.datetime :finished_at
      t.datetime :discarded_at
    end

    create_table :good_job_executions, id: :uuid do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.uuid :active_job_id, null: false
      t.text :job_class
      t.text :queue_name
      t.jsonb :serialized_params
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.text :error
      t.integer :error_event, limit: 2
      t.interval :duration
      t.uuid :process_id
    end

    add_index :good_job_executions, :active_job_id, name: :index_good_job_executions_on_active_job_id
  end
end

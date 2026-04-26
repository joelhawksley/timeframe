# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 5) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "account_users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id", "user_id"], name: "index_account_users_on_account_id_and_user_id", unique: true
    t.index ["account_id"], name: "index_account_users_on_account_id"
    t.index ["user_id"], name: "index_account_users_on_user_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "devices", force: :cascade do |t|
    t.text "api_key"
    t.float "battery_level"
    t.text "cached_image"
    t.datetime "cached_image_at"
    t.string "confirmation_code"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.boolean "demo_mode_enabled", default: false, null: false
    t.text "display_key"
    t.bigint "display_state_crc"
    t.string "display_template", default: "default", null: false
    t.string "firmware_version"
    t.string "friendly_id"
    t.datetime "last_connection_at"
    t.bigint "location_id"
    t.text "mac_address"
    t.string "model", null: false
    t.string "name", null: false
    t.integer "rssi"
    t.text "session_token"
    t.float "temperature"
    t.datetime "updated_at", null: false
    t.text "visionect_serial"
    t.index ["api_key"], name: "index_devices_on_api_key", unique: true
    t.index ["confirmation_code"], name: "index_devices_on_confirmation_code", unique: true
    t.index ["display_key"], name: "index_devices_on_display_key", unique: true
    t.index ["location_id"], name: "index_devices_on_location_id"
    t.index ["mac_address"], name: "index_devices_on_mac_address", unique: true
    t.index ["session_token"], name: "index_devices_on_session_token", unique: true
    t.index ["visionect_serial"], name: "index_devices_on_visionect_serial", unique: true
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "callback_priority"
    t.text "callback_queue_name"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.text "on_discard"
    t.text "on_finish"
    t.text "on_success"
    t.jsonb "serialized_properties"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id", null: false
    t.datetime "created_at", null: false
    t.interval "duration"
    t.text "error"
    t.integer "error_event", limit: 2
    t.datetime "finished_at"
    t.text "job_class"
    t.uuid "process_id"
    t.text "queue_name"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_good_job_executions_on_active_job_id"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lock_type", limit: 2
    t.jsonb "state"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "key"
    t.datetime "updated_at", null: false
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id"
    t.uuid "batch_callback_id"
    t.uuid "batch_id"
    t.text "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "cron_at"
    t.text "cron_key"
    t.text "error"
    t.integer "error_event", limit: 2
    t.integer "executions_count"
    t.datetime "finished_at"
    t.boolean "is_discrete"
    t.text "job_class"
    t.text "labels", array: true
    t.datetime "locked_at"
    t.uuid "locked_by_id"
    t.datetime "performed_at"
    t.integer "priority"
    t.text "queue_name"
    t.uuid "retried_good_job_id"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["cron_key"], name: "index_good_jobs_on_cron_key"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "locations", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.text "latitude", null: false
    t.text "longitude", null: false
    t.text "name", null: false
    t.string "time_zone", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_locations_on_account_id"
  end

  create_table "pending_devices", force: :cascade do |t|
    t.text "api_key"
    t.bigint "claimed_device_id"
    t.datetime "created_at", null: false
    t.string "friendly_id"
    t.text "mac_address"
    t.text "pairing_code", null: false
    t.datetime "updated_at", null: false
    t.index ["claimed_device_id"], name: "index_pending_devices_on_claimed_device_id"
    t.index ["mac_address"], name: "index_pending_devices_on_mac_address", unique: true
    t.index ["pairing_code"], name: "index_pending_devices_on_pairing_code", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "email", null: false
    t.text "magic_link_nonce"
    t.datetime "remember_created_at"
    t.text "remember_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "account_users", "accounts"
  add_foreign_key "account_users", "users"
  add_foreign_key "devices", "locations"
  add_foreign_key "locations", "accounts"
  add_foreign_key "pending_devices", "devices", column: "claimed_device_id"
end

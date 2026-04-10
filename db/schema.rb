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

ActiveRecord::Schema[8.1].define(version: 1) do
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

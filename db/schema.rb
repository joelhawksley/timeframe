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

ActiveRecord::Schema[8.1].define(version: 6) do
  create_table "devices", force: :cascade do |t|
    t.string "api_key"
    t.float "battery_level"
    t.text "cached_image"
    t.datetime "cached_image_at"
    t.datetime "created_at", null: false
    t.boolean "demo_mode_enabled", default: false, null: false
    t.integer "display_state_crc", limit: 8
    t.string "firmware_version"
    t.string "friendly_id"
    t.datetime "last_connection_at"
    t.string "mac_address"
    t.string "model", null: false
    t.string "name", null: false
    t.integer "rssi"
    t.float "temperature"
    t.datetime "updated_at", null: false
    t.string "visionect_serial"
    t.index ["api_key"], name: "index_devices_on_api_key", unique: true
    t.index ["mac_address"], name: "index_devices_on_mac_address", unique: true
    t.index ["visionect_serial"], name: "index_devices_on_visionect_serial", unique: true
  end
end

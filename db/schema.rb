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

ActiveRecord::Schema[7.0].define(version: 2022_12_17_160713) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "google_accounts", force: :cascade do |t|
    t.bigint "user_id"
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "access_token", default: "", null: false
    t.text "refresh_token", default: "", null: false
    t.datetime "expires_at"
    t.boolean "email_enabled", default: false, null: false
    t.jsonb "emails", default: [], null: false
    t.index ["email"], name: "index_google_accounts_on_email"
    t.index ["user_id"], name: "index_google_accounts_on_user_id"
  end

  create_table "google_calendars", force: :cascade do |t|
    t.bigint "google_account_id", null: false
    t.string "uuid", null: false
    t.string "summary", null: false
    t.boolean "enabled", default: false, null: false
    t.string "icon", default: "", null: false
    t.string "letter", default: "", null: false
    t.index ["google_account_id"], name: "index_google_calendars_on_google_account_id"
  end

  create_table "logs", force: :cascade do |t|
    t.string "globalid", null: false
    t.string "event", null: false
    t.string "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "weather"
    t.jsonb "calendar_events", default: [], null: false
    t.string "error_messages", default: [], array: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end

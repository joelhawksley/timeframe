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

ActiveRecord::Schema[7.2].define(version: 2024_06_05_165037) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "api_responses", force: :cascade do |t|
    t.string "name", null: false
    t.json "response", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_api_responses_on_name"
  end

  create_table "google_accounts", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "access_token", default: "", null: false
    t.text "refresh_token", default: "", null: false
    t.datetime "expires_at"
    t.index ["email"], name: "index_google_accounts_on_email"
  end

  create_table "logs", force: :cascade do |t|
    t.string "globalid", null: false
    t.string "event", null: false
    t.string "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end

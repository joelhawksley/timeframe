# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20_201_203_135_158) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'devices', force: :cascade do |t|
    t.bigint 'user_id', null: false
    t.string 'uuid', null: false
    t.string 'template', null: false
    t.integer 'width', null: false
    t.integer 'height', null: false
    t.binary 'current_image'
    t.jsonb 'status', default: '{}', null: false
    t.index ['user_id'], name: 'index_devices_on_user_id'
  end

  create_table 'google_accounts', force: :cascade do |t|
    t.bigint 'user_id'
    t.string 'email', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.text 'access_token', default: '', null: false
    t.text 'refresh_token', default: '', null: false
    t.datetime 'expires_at'
    t.index ['email'], name: 'index_google_accounts_on_email'
    t.index ['user_id'], name: 'index_google_accounts_on_user_id'
  end

  create_table 'google_calendars', force: :cascade do |t|
    t.bigint 'google_account_id', null: false
    t.string 'uuid', null: false
    t.string 'summary', null: false
    t.boolean 'enabled', default: false, null: false
    t.string 'icon', default: '', null: false
    t.string 'letter', default: '', null: false
    t.index ['google_account_id'], name: 'index_google_calendars_on_google_account_id'
  end

  create_table 'users', force: :cascade do |t|
    t.string 'email', default: '', null: false
    t.string 'encrypted_password', default: '', null: false
    t.string 'reset_password_token'
    t.datetime 'reset_password_sent_at'
    t.datetime 'remember_created_at'
    t.integer 'sign_in_count', default: 0, null: false
    t.datetime 'current_sign_in_at'
    t.datetime 'last_sign_in_at'
    t.inet 'current_sign_in_ip'
    t.inet 'last_sign_in_ip'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'location'
    t.jsonb 'weather'
    t.jsonb 'calendar_events', default: [], null: false
    t.string 'token'
    t.string 'error_messages', default: [], array: true
    t.jsonb 'air'
    t.decimal 'latitude', precision: 10, scale: 6
    t.decimal 'longitude', precision: 10, scale: 6
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['reset_password_token'], name: 'index_users_on_reset_password_token', unique: true
    t.index ['token'], name: 'index_users_on_token'
  end
end

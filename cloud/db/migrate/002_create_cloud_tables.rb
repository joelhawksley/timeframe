# frozen_string_literal: true

class CreateCloudTables < ActiveRecord::Migration[8.1]
  def change
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
      t.string :external_id
      t.references :google_account, foreign_key: true
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
  end
end

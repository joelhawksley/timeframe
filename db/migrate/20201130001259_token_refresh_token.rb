# frozen_string_literal: true

class TokenRefreshToken < ActiveRecord::Migration[5.1]
  def change
    add_column :google_accounts, :access_token, :text, default: "", null: false
    add_column :google_accounts, :refresh_token, :text, default: "", null: false
    add_column :google_accounts, :expires_at, :timestamp
  end
end

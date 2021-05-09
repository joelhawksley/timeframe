# frozen_string_literal: true

class RemoveGoogleAuthorization < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :google_authorization
    remove_column :google_accounts, :google_authorization
  end
end

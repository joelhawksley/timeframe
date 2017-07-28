class AddGoogleAuthorizationToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :google_authorization, :jsonb, null: false, default: {}
  end
end

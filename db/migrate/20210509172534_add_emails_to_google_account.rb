class AddEmailsToGoogleAccount < ActiveRecord::Migration[6.1]
  def change
    add_column :google_accounts, :emails, :jsonb, default: [], null: false
  end
end

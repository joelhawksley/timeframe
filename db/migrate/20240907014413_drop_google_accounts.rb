class DropGoogleAccounts < ActiveRecord::Migration[7.2]
  def change
    drop_table :google_accounts
  end
end

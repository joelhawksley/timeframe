class RemoveEmail < ActiveRecord::Migration[7.0]
  def change
    remove_column :google_accounts, :email_enabled
    remove_column :google_accounts, :emails
  end
end

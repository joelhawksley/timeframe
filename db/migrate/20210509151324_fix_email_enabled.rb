class FixEmailEnabled < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :email_enabled
    add_column :google_accounts, :email_enabled, :boolean, default: false, null: false
  end
end

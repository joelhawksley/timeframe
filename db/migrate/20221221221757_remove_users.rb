class RemoveUsers < ActiveRecord::Migration[7.0]
  def change
    drop_table :users
    remove_column :google_accounts, :user_id
  end
end

class Updates < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :location
    remove_column :users, :token
    remove_column :users, :air
    add_column :users, :email_enabled, :boolean, default: false, null: false
  end
end

class AddAirToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :air, :jsonb
  end
end

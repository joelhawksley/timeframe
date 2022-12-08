class RemoveUserLatLong < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :latitude
    remove_column :users, :longitude
  end
end

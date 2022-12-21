class RemoveWeatherFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :weather
  end
end

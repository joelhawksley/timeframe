class RemoveCalendarEventsFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :calendar_events
  end
end

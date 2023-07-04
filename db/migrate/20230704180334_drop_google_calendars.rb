class DropGoogleCalendars < ActiveRecord::Migration[7.0]
  def change
    drop_table :google_calendars
  end
end

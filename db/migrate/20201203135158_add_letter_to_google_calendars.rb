class AddLetterToGoogleCalendars < ActiveRecord::Migration[5.1]
  def change
    add_column :google_calendars, :icon, :string, default: "", null: false
    add_column :google_calendars, :letter, :string, default: "", null: false
  end
end

class CreateGoogleCalendars < ActiveRecord::Migration[5.1]
  def change
    create_table :google_calendars do |t|
      t.references :google_account, index: true, null: false
      t.string :uuid, null: false
      t.string :summary, null: false
      t.boolean :enabled, null: false, default: false
    end
  end
end

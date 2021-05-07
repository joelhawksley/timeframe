# frozen_string_literal: true

class AddCalendarEventsToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :calendar_events, :jsonb, default: [], null: false
  end
end

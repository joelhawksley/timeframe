# frozen_string_literal: true

class DropSkiReports < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :ski_reports
  end
end

class DropSkiReports < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :ski_reports
  end
end

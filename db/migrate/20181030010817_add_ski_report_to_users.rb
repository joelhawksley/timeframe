class AddSkiReportToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :ski_reports, :jsonb, default: [], null: false
  end
end

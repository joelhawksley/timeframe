class AddApplicationLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :logs do |t|
      t.string :globalid, null: false
      t.string :event, null: false
      t.string :message, null: false
      t.timestamps null: false
    end
  end
end

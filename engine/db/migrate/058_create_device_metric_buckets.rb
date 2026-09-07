# frozen_string_literal: true

class CreateDeviceMetricBuckets < ActiveRecord::Migration[8.1]
  def change
    create_table :device_metric_buckets do |t|
      t.references :device, null: false, foreign_key: {on_delete: :cascade}
      t.datetime :bucket_at, null: false
      t.float :battery_percent_last
      t.float :battery_percent_min
      t.float :battery_percent_max
      t.float :battery_voltage_last
      t.float :battery_voltage_min
      t.float :battery_voltage_max
      t.boolean :charging
      t.integer :battery_sample_count, null: false, default: 0
      t.integer :poll_update_count, null: false, default: 0
      t.integer :poll_no_update_count, null: false, default: 0

      t.timestamps
    end

    add_index :device_metric_buckets, [:device_id, :bucket_at], unique: true
  end
end

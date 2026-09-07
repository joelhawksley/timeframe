# frozen_string_literal: true

class DeviceMetricBucket < ActiveRecord::Base
  belongs_to :device

  class << self
    def record_poll!(device:, battery_percent:, battery_voltage:, charging:, no_update:)
      record!(device:, battery_percent:, battery_voltage:, charging:, poll_no_update_count: no_update ? 1 : 0)
    end

    def record_update!(device:)
      record!(device:, poll_update_count: 1)
    end

    private

    def record!(device:, battery_percent: nil, battery_voltage: nil, charging: nil, poll_update_count: 0, poll_no_update_count: 0)
      bucket = create_or_find_by!(device:, bucket_at: Time.current.beginning_of_hour)
      bucket.with_lock do
        attributes = {
          poll_update_count: bucket.poll_update_count + poll_update_count,
          poll_no_update_count: bucket.poll_no_update_count + poll_no_update_count
        }
        if battery_percent
          attributes.merge!(
            battery_percent_last: battery_percent,
            battery_percent_min: [bucket.battery_percent_min, battery_percent].compact.min,
            battery_percent_max: [bucket.battery_percent_max, battery_percent].compact.max,
            battery_sample_count: bucket.battery_sample_count + 1
          )
        end
        if battery_voltage
          attributes.merge!(
            battery_voltage_last: battery_voltage,
            battery_voltage_min: [bucket.battery_voltage_min, battery_voltage].compact.min,
            battery_voltage_max: [bucket.battery_voltage_max, battery_voltage].compact.max
          )
        end
        attributes[:charging] = charging unless charging.nil?
        bucket.update!(attributes)
      end
      bucket
    end
  end
end

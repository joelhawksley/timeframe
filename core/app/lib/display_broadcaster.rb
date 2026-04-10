# frozen_string_literal: true

class DisplayBroadcaster
  # Track last known data hash per device to avoid redundant broadcasts
  @last_hashes = {}
  @mutex = Mutex.new

  class << self
    def broadcast_if_changed(device)
      data = view_object_for(device)
      data_hash = Digest::MD5.hexdigest(data.except(:current_time).to_json)

      should_broadcast = @mutex.synchronize do
        if @last_hashes[device.id] != data_hash
          @last_hashes[device.id] = data_hash
          true
        else
          false
        end
      end

      if should_broadcast
        DisplayChannel.broadcast_to(device, {action: "refresh", deploy_time: DEPLOY_TIME})
        Rails.logger.info "[DisplayBroadcaster] Content pushed to #{device.name}"
      end
    end

    def broadcast_all_mira_displays
      Device.where(model: "boox_mira_pro").find_each do |device|
        broadcast_if_changed(device)
      rescue => e
        Rails.logger.error "[DisplayBroadcaster] Failed for #{device.name}: #{e.message}"
      end
    end

    def clear_hash(device_id)
      @mutex.synchronize { @last_hashes.delete(device_id) }
    end

    private

    # Override in host apps for app-specific display data
    def view_object_for(device)
      if device.demo_mode_enabled?
        DemoDisplayContent.new.call
      else
        DisplayContent.new.call
      end
    end
  end
end

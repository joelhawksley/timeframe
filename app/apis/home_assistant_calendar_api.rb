class HomeAssistantCalendarApi < Api
  MDI_CSS = File.read(Rails.root.join("public/css/mdi/materialdesignicons.css")).freeze

  def initialize(config = Timeframe::Application.config.local)
    @config = config
  end

  def fetch
    start_time = (Time.now - 1.day).utc.iso8601
    end_time = (Time.now + 5.days).utc.iso8601

    out = []
    icons = fetch_calendar_icons

    Timeframe::Application.config.local["calendars"].each do |calendar|
      next unless calendar["entity_id"].present?

      res = HTTParty.get("#{url}/#{calendar["entity_id"]}?start=#{start_time}&end=#{end_time}", headers: headers)

      res.map! do |event|
        event["calendar_entity_id"] = calendar["entity_id"]
        event["calendar_name"] = calendar["name"]

        event["starts_at"] = event["start"]["date"] || event["start"]["dateTime"]

        event["ends_at"] = event["end"]["date"] || event["end"]["dateTime"]

        event["icon"] = calendar["icon"] || icons[calendar["entity_id"]] || "calendar"

        event["id"] = event["uid"]

        event.delete("uid")
        event.delete("start")
        event.delete("end")
        event.delete("recurrence_id")
        event.delete("rrule")
        event.delete("calendar_entity_id")
        event.delete("calendar_name")

        event
      end

      out.concat(res)
    end

    save_response(out.compact)
  end

  def prepare_response(response)
    response
  end

  def fetch_calendar_icons
    states_url = @config["home_assistant_api_url"]
    icons = {}

    Timeframe::Application.config.local["calendars"].each do |calendar|
      next unless calendar["entity_id"].present?
      next if calendar["icon"].present?

      begin
        res = HTTParty.get("#{states_url}/#{calendar["entity_id"]}", headers: headers)
        if res.code == 200
          icon = res.dig("attributes", "icon")
          if icon.present?
            icon_name = icon.sub("mdi:", "")
            icons[calendar["entity_id"]] = icon_name if MDI_CSS.include?(".mdi-#{icon_name}::before")
          end
        end
      rescue
        # Fall back to default icon if state lookup fails
      end
    end

    icons
  end

  def headers
    {
      Authorization: "Bearer #{@config["home_assistant_token"]}",
      "content-type": "application/json"
    }
  end

  def private_mode?
    current_time = DateTime.now.in_time_zone(HomeAssistantConfigApi.new.time_zone)

    data.any? { it.summary == "timeframe-private" && it.starts_at <= current_time && it.ends_at >= current_time }
  end

  def data
    @data ||= super.map { CalendarEvent.new(**it.symbolize_keys!) }
  end
end

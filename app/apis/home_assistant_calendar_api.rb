class HomeAssistantCalendarApi < Api
  def initialize(config = Timeframe::Application.config.local)
    @config = config
  end

  def fetch
    start_time = (Time.now - 1.day).utc.iso8601
    end_time = (Time.now + 5.days).utc.iso8601

    out = []

    Timeframe::Application.config.local["calendars"].each do |calendar|
      next unless calendar["entity_id"].present?

      res = HTTParty.get("#{url}/#{calendar["entity_id"]}?start=#{start_time}&end=#{end_time}", headers: headers)

      res.map! do |event|
        event["calendar_entity_id"] = calendar["entity_id"]
        event["calendar_name"] = calendar["name"]

        event["starts_at"] = event["start"]["date"] || event["start"]["dateTime"]

        event["ends_at"] = event["end"]["date"] || event["end"]["dateTime"]

        event["icon"] = calendar["icon"]

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

  def headers
    {
      Authorization: "Bearer #{@config["home_assistant_token"]}",
      "content-type": "application/json"
    }
  end

  def private_mode?
    current_time = DateTime.now.in_time_zone(Timeframe::Application.config.local["timezone"])

    data.any? { it.summary == "timeframe-private" && it.starts_at <= current_time && it.ends_at >= current_time }
  end

  def data
    @data ||= super.map { CalendarEvent.new(**it.symbolize_keys!) }
  end
end

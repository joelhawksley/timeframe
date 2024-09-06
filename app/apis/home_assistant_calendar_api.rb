class HomeAssistantCalendarApi < Api
  def initialize(config = Timeframe::Application.config.local)
    @config = config
  end

  def prepare_response(response)
    start_time = (Time.now - 1.day).utc.iso8601
    end_time = (Time.now + 5.days).utc.iso8601

    out = []

    response.each do |calendar|
      res = HTTParty.get("#{url}/#{calendar["entity_id"]}?start=#{start_time}&end=#{end_time}", headers: headers)
      config = Timeframe::Application.config.local["calendars"].find { _1["entity_id"] == calendar["entity_id"] }

      res.map! do |event|
        event["calendar_entity_id"] = calendar["entity_id"]
        event["calendar_name"] = calendar["name"]

        event["starts_at"] = event["start"]["date"] || event["start"]["dateTime"]

        event["ends_at"] = event["end"]["date"] || event["end"]["dateTime"]

        if config
          event["icon"] = config["icon"]
          event["letter"] = config["letter"]
        end

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

    out
  end

  def headers
    {
      Authorization: "Bearer #{@config["home_assistant_token"]}",
      "content-type": "application/json"
    }
  end

  def data
    @data ||= super.map { CalendarEvent.new(**_1.symbolize_keys!) }
  end
end

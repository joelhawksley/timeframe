# frozen_string_literal: true

class GoogleService
  def self.call
    service = new

    Value.find_by_key("calendar_events").update(value: service.events)
  rescue => e
    Log.create(
      globalid: "GoogleService",
      event: "call_error",
      message: e.message
    )
  end

  def self.client_options
    {
      client_id: ENV["GOOGLE_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"],
      authorization_uri: "https://accounts.google.com/o/oauth2/auth",
      token_credential_uri: "https://accounts.google.com/o/oauth2/token",
      scope: "#{Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY} #{Google::Apis::PeopleV1::AUTH_CONTACTS_READONLY} #{Google::Apis::PeopleV1::AUTH_USERINFO_PROFILE} #{Google::Apis::PeopleV1::AUTH_CONTACTS_OTHER_READONLY} #{Google::Apis::GmailV1::AUTH_GMAIL_READONLY}",
      redirect_uri: ENV["GOOGLE_REDIRECT_URI"],
      access_type: "offline"
    }
  end

  attr_reader :events

  def initialize
    @events = calendar_events
  end

  private

  def calendar_events
    events = {}

    GoogleAccount.all.each do |google_account|
      client = Signet::OAuth2::Client.new(self.class.client_options)

      begin
        client.update!(
          refresh_token: google_account.refresh_token,
          access_token: google_account.access_token,
          expires_in: 3600
        )
      rescue => e
        Log.create(
          globalid: google_account.to_global_id,
          event: "client_refresh_error",
          message: e.message
        )
      end

      if google_account.email_enabled?
        service = service = Google::Apis::GmailV1::GmailService.new
        service.authorization = client

        messages =
          service
            .list_user_messages("me", q: "in:inbox is:unread")
            .messages

        if messages
          google_account.update(
            emails: messages.map(&:id).map do |message_id|
              message = service.get_user_message("me", message_id)

              {
                from: message.payload.headers.find { |h| h.name == "From" }&.value,
                subject: message.payload.headers.find { |h| h.name == "Subject" }&.value
              }
            end
          )
        else
          google_account.update(emails: [])
        end
      end

      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = client

      begin
        calendars = service.list_calendar_lists.items
      rescue => e
        Log.create(
          globalid: google_account.to_global_id,
          event: "list_calendar_lists",
          message: e.message
        )
      end

      next unless calendars.present?

      calendars.each_with_index do |calendar, _index|
        calendar_record = google_account.google_calendars.find_by(uuid: calendar.id)

        if calendar_record
          calendar_record.update(summary: calendar.summary)
        else
          calendar_record =
            google_account.google_calendars.create(uuid: calendar.id, summary: calendar.summary)
        end

        next unless calendar_record.enabled?

        service.list_events(calendar.id, max_results: 250, single_events: true, order_by: "startTime",
                                         time_min: (DateTime.now - 2.weeks).iso8601).items.each_with_index do |event, _index_2|
          own_attendee = event.attendees.to_a.find { |attendee| attendee.email == calendar.id }

          # exclude declined events
          next if own_attendee && own_attendee.response_status == "declined"

          # exclude blank events
          next unless event.summary.present?

          event_json = event.as_json

          start_i =
            if event_json["start"].key?("date")
              ActiveSupport::TimeZone[Timeframe::Application::LOCAL_TZ].parse(event_json["start"]["date"]).utc.to_i
            else
              ActiveSupport::TimeZone[Timeframe::Application::LOCAL_TZ].parse(event_json["start"]["date_time"]).utc.to_i
            end

          end_i =
            if event_json["end"].key?("date")
              # Subtract 1 second, as Google gives us the end date as the following day, not the end of the current day
              ActiveSupport::TimeZone[Timeframe::Application::LOCAL_TZ].parse(event_json["end"]["date"]).utc.to_i - 1
            else
              ActiveSupport::TimeZone[Timeframe::Application::LOCAL_TZ].parse(event_json["end"]["date_time"]).utc.to_i
            end

          counter =
            if (1900..2100).cover?(event_json["description"].to_s.to_i)
              Date.today.year - event_json["description"].to_s.to_i
            end

          next unless
                !event_json["description"].to_s.downcase.include?("timeframe-omit") &&
                event_json["summary"] != "."

          events[event.id] = event_json.slice(
            "start",
            "end",
            "location"
          ).merge(
            background_color: event_json["color"] || calendar.background_color,
            foreround_color: event_json["color"] || calendar.foreground_color,
            summary: event_json["summary"],
            counter: counter,
            description: event_json["description"],
            calendar: calendar.summary,
            icon: calendar_record.icon,
            letter: calendar_record.letter,
            start_i: start_i,
            end_i: end_i,
            all_day: event_json["start"].key?("date") || ((end_i - start_i) > 86_400)
          ).symbolize_keys!
        end
      end
    end

    events.values.sort_by { |event| event[:start_i] }
  end
end

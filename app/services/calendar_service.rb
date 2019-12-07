class CalendarService
  def self.call(user)
    user.update(calendar_events: new.fetch_calendar_events(user))
  rescue => e
    user.update(error_messages: user.error_messages << e.message)
  end

  def self.client_options
    {
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY,
      redirect_uri: Rails.application.secrets.redirect_uri,
      access_type: 'offline'
    }
  end

  def fetch_calendar_events(user)
    calendar_events(user)
  end

  private

  def calendar_events(user)
    client = Signet::OAuth2::Client.new(self.class.client_options)
    client.expires_in = Time.now + 1_000_000

    client.update!(user.google_authorization)

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    begin
      events = []

      service.list_calendar_lists.items.each_with_index do |calendar, index|
        service.list_events(calendar.id, max_results: 250, single_events: true, order_by: 'startTime', time_min: (DateTime.now - 2.weeks).iso8601).items.each_with_index do |event, index_2|
          event_json = event.as_json

          start_i =
            if event_json["start"].key?("date")
              ActiveSupport::TimeZone["America/Denver"].parse(event_json["start"]["date"]).utc.to_i
            else
              ActiveSupport::TimeZone["America/Denver"].parse(event_json["start"]["date_time"]).utc.to_i
            end

          end_i =
            if event_json["end"].key?("date")
              # Subtract 1 second, as Google gives us the end date as the following day, not the end of the current day
              ActiveSupport::TimeZone["America/Denver"].parse(event_json["end"]["date"]).utc.to_i - 1
            else
              ActiveSupport::TimeZone["America/Denver"].parse(event_json["end"]["date_time"]).utc.to_i
            end

          summary =
            if (1900..2100).cover?(event_json["description"].to_s.to_i)
              "#{event_json["summary"]} (#{Date.today.year - event_json["description"].to_s.to_i})"
            else
              event_json["summary"]
            end

          events << event_json.slice(
              "start",
              "end",
              "location"
            ).merge(
              color: calendar.background_color,
              summary: summary,
              description: event_json["description"],
              calendar: calendar.summary,
              icon: icon_for_title("#{calendar.summary} #{event_json["summary"]}"),
              start_i: start_i,
              end_i: end_i,
              all_day: event_json["start"].key?("date")
            ).symbolize_keys!
        end
      end

      events.sort_by { |event| event[:start_i] }
    rescue Google::Apis::AuthorizationError => exception
      response = client.refresh!

      user.update(google_authorization: user.google_authorization.merge(response))

      retry
    end
  end

  def icon_for_title(title)
    out = ''

    ICON_MATCHES.to_a.each do |icon, regex|
      if eval("#{regex}i") =~ title
        out = icon
        break
      end
    end

    out
  end

  ICON_MATCHES = {
    "calendar" => "/(holiday)/",
    "cutlery" => "/(dinner)/",
    "paw" => "/(captain|olive)/",
    "male" => "/(joel|taylor)/",
    "female" => "/(caitlin|danielle)/",
    "heart" => "/(us|home)/",
    "github" => "/(on call)/",
    "birthday-cake" => "/(birthdays)/",
  }
end

namespace :fetch do
  task all: :environment do
    User.all.each do |user|
      weather = HTTParty.get("http://api.wunderground.com/api/f79789b09f774c40/forecast/astronomy/conditions/q/#{user.location.delete(" ")}.json").as_json
      user.update(weather: weather, calendar_events: calendar_events(user))
    end
  end
end

def calendar_events(user)
  client = Signet::OAuth2::Client.new({
    client_id: Rails.application.secrets.google_client_id,
    client_secret: Rails.application.secrets.google_client_secret,
    token_credential_uri: 'https://accounts.google.com/o/oauth2/token'
  })

  client.update!(user.google_authorization)

  service = Google::Apis::CalendarV3::CalendarService.new
  service.authorization = client

  begin
    events = []

    service.list_calendar_lists.items.each_with_index do |calendar, index|
      service.list_events(calendar.id, max_results: 10, single_events: true, order_by: 'startTime', time_min: DateTime.now.beginning_of_day.iso8601).items.each do |event|
        event_json = event.as_json

        start_i =
          if event_json["start"].key?("date")
            DateTime.parse(event_json["start"]["date"]).in_time_zone("America/Denver").to_i
          else
            DateTime.parse(event_json["start"]["date_time"]).to_i
          end

        end_i =
          if event_json["end"].key?("date")
            DateTime.parse(event_json["end"]["date"]).in_time_zone("America/Denver").to_i
          else
            DateTime.parse(event_json["end"]["date_time"]).to_i
          end

        events << event_json.slice("start", "end", "summary").merge(calendar: calendar.summary, start_i: start_i, end_i: end_i, all_day: event_json["start"].key?("date")).symbolize_keys!
      end
    end

    events.sort_by { |event| event[:start_i] }
  rescue Google::Apis::AuthorizationError => exception
    response = client.refresh!

    user.update(google_authorization: user.google_authorization.merge(response))

    retry
  end
end

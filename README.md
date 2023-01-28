# Timeframe

A web application for displaying information from various APIs on digital signage.

## Project goals

- Serve as a test bed for learning new technologies.
- Long term: I expect to run this application for years, if not decades.
- Stability: I expect the application to run without maintenace indefinitely.
- Availability: 100% uptime.
- Fault tolerance: the application functions when no internet connection is available. (Comcast is not 100% reliable and I reset my internet connection daily for 5m in the early morning)

## Functional architecture

- Signage endpoints
    - Visionect 13" displays (/thirteen)
        - Fetched by [Visionect Software Suite](https://docs.visionect.com/VisionectSoftwareSuite/index.html) running on local network and displayed on [13" Place and Play](https://www.visionect.com/shop/place-play-13/) devices. Fetch interval is currently 10m.
    - Boox Mira Pro (/mira)
        - Fetched by a client Mac Mini with a [Boox Mira Pro](https://shop.boox.com/products/mira) (25.3" 3200x1800px e-Paper display) running Google Chrome full screen.
        - Uses HTMX to live-reload calendar events and Sonos state. (From /sonos and /timeline)
        - Self-refreshes entire every 5m.
- Admin
    - Configuration page (root path)
        - Google OAuth flow
        - Configuration of Google calendars
    - Operational logs (/logs)
    - Weather debugging page (/weather_data)
    - Calendar debugging page (/calendar_data)
- Cron jobs
    - `rake fetch:tokens` refreshes Google access tokens at the top of every hour.
    - `rake fetch:weather` fetches weather data from Weather.gov, WeatherFlow (home weather station), and Wunderground every 5m.
    - `rake fetch:google` fetches Google data every 5m.

## Todo list

- Ensure tests and lints pass pre-commit
- Improve test coverage
- Improve architecture of application
- Experiment with technologies (Hanami, Dry RB, Sorbet, HStore etc)
- Integrate with Home Assistant to show whether mail has been delivered today
- Improve OAuth refresh token availability
- Improve local workflow as debugging is difficult due to using development server as production

## Local development

### Getting started

1) Ensure you have Postgres installed.
1) Optional: Install and run https://github.com/jishi/node-sonos-http-api.
1) `bundle install`
1) `npm install`
1) `rails db:setup`
1) Copy `.env.example` to `.env` and set the given values.
1) `rails s`
1) Visit [http://localhost:3000](http://localhost:3000)

_Note: OAuth setup is not documented_

### Testing

1) `bundle exec rake`

### Deploying

Currently, Timeframe runs on a local Mac Mini in development mode. There is no production deployment.

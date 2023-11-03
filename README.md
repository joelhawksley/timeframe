# Timeframe

A web application for displaying information from various APIs on digital signage.

## Project goals

- Serve as a test bed for learning new technologies.
- Long term: I expect to run this application for years, if not decades.
- Stability: I expect the application to run without maintenace indefinitely.
- Availability: 100% uptime.
- Fault tolerance: the application functions when no internet connection is available. (Comcast is not 100% reliable and I reset my internet connection daily for 5m in the early morning)

## Architecture

- Signage endpoints
    - Visionect 13" displays (/thirteen)
        - Fetched by [Visionect Software Suite](https://docs.visionect.com/VisionectSoftwareSuite/index.html) running on local network and displayed on [13" Place and Play](https://www.visionect.com/shop/place-play-13/) devices. Fetch interval is currently 10m.
    - Boox Mira Pro (/mira)
        - Fetched by a client Mac Mini with a [Boox Mira Pro](https://shop.boox.com/products/mira) (25.3" 3200x1800px e-Paper display) running Google Chrome full screen.
        - Self-refreshes entire screen every 5s.
- Admin
    - Configuration page (root path)
        - Google OAuth flow
    - Operational logs (/logs)
    - Weather debugging page (/weather_data)
- Cron jobs
    - `rake fetch:tokens` refreshes Google access tokens at the top of every hour.
    - `rake fetch:weather` fetches weather data from Weather.gov, WeatherFlow (home weather station), and Wunderground every 5m.
    - `rake fetch:google` fetches Google data every 5m.

## Todo list

- Move all config into config.yml (or use AnywayConfig from Palkan?)
- automate deploys to local server
- set up remote chrome debugging on client display
- sync tempest weather data
- make /logs easier to scan (use details element?)
- Dither images using this technique: https://news.ycombinator.com/item?id=37837009
- Set up ruby and/or Standard LSP
- Ensure lints pass pre-commit
- Experiment with technologies (Hanami, Dry RB, Sorbet, HStore, Phlex, etc)
- Integrate with Home Assistant to show whether mail has been delivered today
- remove Postgres dependency for better application portability

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

To upgrade Visionect: `docker-compose pull && docker-compose up -d` in Visionect directory

Run Sonos server: `cd node-sonos-http-api && npm start`

Rails server: `rails s -p 3000 -b 0.0.0.0`

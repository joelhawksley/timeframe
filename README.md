# Timeframe

A web application for displaying information from various APIs on digital signage.

## Project goals

- Serve as a test bed for learning new technologies.
- Long term: I expect to run this application for years, if not decades.
- Stability: I expect the application to run without maintenance indefinitely.
- Availability: 100% uptime.
- Fault tolerance: the application functions when no internet connection is available.

## Architecture

- Signage endpoints
    - Visionect 13" displays (/thirteen)
        - Fetched by [Visionect Software Suite](https://docs.visionect.com/VisionectSoftwareSuite/index.html) running on local network and displayed on [13" Place and Play](https://www.visionect.com/shop/place-play-13/) devices. Fetch interval is currently 10m.
    - Boox Mira Pro (/mira)
        - Fetched by a client Mac Mini with a [Boox Mira Pro](https://shop.boox.com/products/mira) (25.3" 3200x1800px e-Paper display) running Google Chrome full screen.
        - Self-refreshes entire screen every 1s.

## Todo list

- add health checks for home assistant automations
- integrate with RFID jukebox: https://github.com/maddox/magic-cards
- set up remote chrome debugging on client display
- sync tempest weather data
- Dither images using this technique: https://news.ycombinator.com/item?id=37837009
- Integrate with Home Assistant to show whether mail has been delivered today

## Local development

### Setup

1) Optional: Install and run https://github.com/jishi/node-sonos-http-api.
2) `bundle install`
3) `rails db:setup`
4) Copy `.config.example.yml` to `.config.yml` and set the given values.
5) `rails s`
6) Visit [http://localhost:3000](http://localhost:3000)

### Testing

`bundle exec rake`

### Deploying

Currently, Timeframe runs on a local Mac Mini in development mode. There is no production deployment.

To fetch the latest version: `git fetch --all && git reset --hard origin/main`

To upgrade Visionect: `docker-compose pull && docker-compose up -d`

Run Sonos server: `cd node-sonos-http-api && npm start`

Rails server: `RUN_BG=true rails s -p 80 -b 0.0.0.0 --no-log-to-stdout`

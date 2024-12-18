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
        - Self-refreshes entire screen every 2s.

## Todo list

- remove .stub from tests in favor of dependency injection
- run Rails server with `launchd`
- add health checks for home assistant automations
- Use a pi for kiosk mode instead of a mac mini
- Drop redis
- Drop slim

## Local development

### Setup

1) `bundle install`
2) `rails db:setup`
3) Copy `.config.yml`from a friend.
4) `rails s`
5) Visit [http://localhost:3000](http://localhost:3000)

### Testing

`bundle exec rake`

### Deploying

Currently, Timeframe runs on a local Mac Mini in development mode. There is no production deployment.

To fetch the latest version: `git fetch --all && git reset --hard origin/main`

To upgrade Visionect: `docker-compose pull && docker-compose up -d`

Rails server: `SECRET_KEY_BASE="foo" RAILS_ENV=production rails s -p 80 -b 0.0.0.0 --no-log-to-stdout`

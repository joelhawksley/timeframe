# Timeframe

An e-paper calendar, weather, and smart home family dashboard

## Project goals

- Serve as a test bed for learning new technologies.
- Longevity: I expect to run this application for years, if not decades.
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

## Local development

### Setup

1) `bundle install`
2) Copy `config.yml`from a friend.
3) `rails s`
4) Visit [http://localhost:3000](http://localhost:3000)

### Testing

`bundle exec rake`

### Deploying

To fetch the latest version: `git fetch --all && git reset --hard origin/main`

To upgrade Visionect: `docker-compose pull && docker-compose up -d`

Rails server: `RAILS_ENV=production rails s -p 80 -b 0.0.0.0 --no-log-to-stdout`

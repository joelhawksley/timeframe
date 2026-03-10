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
        - Fetched by a client Mac Mini with a [Boox Mira Pro](https://shop.boox.com/products/boox-mira-procolor-version) (25.3" 3200x1800px e-Paper display) running Google Chrome full screen.
        - Self-refreshes entire screen every 2s.

## Dependencies

- Home Assistant
- Apple WeatherKit API key (optional, for next-hour precipitation forecast)

## Home Assistant App (add-on) Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**
2. Click the three-dot menu (⋮) → **Repositories**
3. Add this repository URL: `https://github.com/joelhawksley/timeframe`
4. Find **Timeframe** in the add-on store and click **Install**
5. (Optional) Add your Apple Weather API key under Configuration to enable next-hour forecasts.
6. Click **Start**
7. Access the app at port 8099 (e.g. `http://homeassistant.local:8099`)

No configuration is required — the add-on automatically uses the Home Assistant Supervisor API.

## Local development

### Configuration

1) Create `config.yml` from `config.yml.example`
2) Fill out `home_assistant_token` by creating a long-lived access token under Home Assistant > Profile > Security

### Setup

1) `bundle install`
2) `rails s`
3) Visit [http://localhost:3000/mira](http://localhost:3000/mira) or [http://localhost:3000/thirteen](http://localhost:3000/thirteen)

### Testing

`bundle exec rake`

### Deploying

To fetch the latest version: `git fetch --all && git reset --hard origin/main`

Rails server: `RAILS_ENV=production rails s -p 80 -b 0.0.0.0 --no-log-to-stdout`

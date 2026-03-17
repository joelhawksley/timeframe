# Timeframe

An e-paper calendar, weather, and smart home family dashboard

![Timeframe display in phone nook](https://hawksley.org/img/posts/2026-02-17-timeframe/nook-wide.jpg)

## Project goals

- Serve as a test bed for learning new technologies.
- Longevity: I expect to run this application for years, if not decades.
- Stability: I expect the application to run without maintenance indefinitely.
- Availability: 100% uptime.
- Fault tolerance: the application functions when no internet connection is available.

## Supported displays

- Visionect [Place & Play 13](https://www.visionect.com/shop/place-play-13/) / [Joan 13 Pro](https://getjoan.com/shop/joan-13-pro/) - designed for 10m update interval
- Boox [Mira Pro](https://shop.boox.com/products/boox-mira-procolor-version) - Self-refreshes every 2s for realtime updates

## Dependencies

- Home Assistant

## Home Assistant App (add-on) Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**
2. Click the three-dot menu (⋮) → **Repositories**
3. Add this repository URL: `https://github.com/joelhawksley/timeframe`
4. Find **Timeframe** in the add-on store and click **Install**
5. Click **Start**
6. Access the app at port 8099 (e.g. `http://homeassistant.local:8099`)

## Local development

### Configuration

1) Create `config.yml` from `config.yml.example`
2) Fill out `home_assistant_token` by creating a long-lived access token under Home Assistant > Profile > Security

### Setup

1) `bundle install`
2) `rails s`
3) Visit [http://localhost:3000](http://localhost:3000)

### Testing

`bundle exec rake`

## License

This project is licensed under the [O'Saasy License](https://osaasy.dev/) — see [LICENSE.md](LICENSE.md) for details.

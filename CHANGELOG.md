## [2.9.0] - 2026-04-29

### Added
- Two-day portrait display template for TRMNL and reTerminal E1001
- TRMNL API: capture device telemetry (firmware version, battery, RSSI) from request headers
- TRMNL API: added missing response fields (status, firmware_url, temperature_profile)
- Boox Mira 13.3" device support

### Fixed
- Fixed timezone handling in display templates (Date.current → timezone-aware)
- Deleting a device now destroys associated pending devices

## [2.8.0] - 2026-04-14

### Added
- Support label-less icons

## [2.7.0] - 2026-04-12

### Fixed
- Fix Postgres misconfiguration

## [2.6.0] - 2026-04-12

### Fixed
- Fixed broken docker build

## [2.5.0] - 2026-04-12

### Fixed
- Fixed broken docker build

## [2.4.0] - 2026-04-12

### Changed
- Split up repository to only include single-tenant functionality.

## [2.3.0] - 2026-04-07

### Fixed
- Fix bug where weather and calendar data was marked unhealthy and thus hidden before refresh interval.

## [2.2.0] - 2026-04-07

### Changed
- Display routes are now named `*/devices/*`.

## [2.1.0] - 2026-04-07

### Changed
- Move internal display route to be nested under location.

## [2.0.7] - 2026-04-06

### Fixed
- Fixed bug in Dockerfile that prevented build from working in Home Assistant.

## [2.0.6] - 2026-04-06

### Fixed
- Fixed bug in Dockerfile that prevented build from working in Home Assistant.

## [2.0.5] - 2026-04-06

### Fixed
- Fixed bug in Dockerfile that prevented build from working in Home Assistant.

## [2.0.4] - 2026-04-06

### Fixed
- Fixed bug in Dockerfile that prevented build from working in Home Assistant.

## [2.0.3] - 2026-04-06

### Fixed
- Fixed bug in Dockerfile that prevented build from working in Home Assistant.

## [2.0.2] - 2026-04-06

### Fixed
- Fixed bug in Dockerfile that prevented build from working in Home Assistant.

## [2.0.1] - 2026-04-06

### Fixed
- Fixed bug in Dockerfile that prevented build from working in Home Assistant.

## [2.0.0] - 2026-04-06

_Lots of breaking changes in this release, most notably moving the repository to [https://](https://github.com/timeframe/timeframe)._

### Added
- Token-authenticated display URLs for Visionect devices (`/d/:id?key=...`)
- Signed, expiring screenshot URLs for TRMNL devices (1-minute SGID)
- Rack::Attack rate limiting on display and pairing endpoints
- Device card grid with live preview on dashboard
- Confirmation modals for device deletion and URL regeneration
- Re-pair flow for Boox devices with disconnection detection (>1 hour)
- Device session tokens for Boox displays (one session per device)
- Action Cable with PostgreSQL adapter for real-time Mira display updates
- DisplayBroadcaster: push-based updates triggered by HA state changes
- Client-side clock, date, and top-of-hour flash for Mira displays
- Status page at `/status` for Home Assistant API diagnostics

### Changed
- Pairing and confirmation codes are now 6-digit numeric (were alphanumeric). Pairing codes expire after 15 minutes.
- Display templates are now stateless (all logic in DisplayContent/DemoDisplayContent)
- Mira polling replaced with Action Cable push (was 86,400 requests/day)

### Security
- Display URLs require authentication (session or token)
- Rack::Attack rate limiting on token displays and pairing
- Identical 401 responses prevent display enumeration
- Referrer-Policy: no-referrer on token display responses
- Device session tokens scoped per-device, rotated on re-pair

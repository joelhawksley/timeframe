# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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

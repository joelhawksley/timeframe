# timeframe

A Rails application for displaying information from Google Calendar and Dark Sky on Visionect displays.

## History

I've been running this application in some form since 2015. I've open-sourced it mainly to provide a reference example for working with the Visionect ecosystem in Ruby and Rails.

## Getting started

1) Ensure you have Postgres installed.
1) `bundle install`
1) `rails db:setup`
1) Copy `.env.example` to `.env` and set the given values.
1) `rails s`
1) Visit [http://localhost:3000](http://localhost:3000)

## Deploying

1) Create app, add Hobby Dev Postgres and Scheduler. Set config variables from .env.example.
2) `git push heroku`
3) Add scheduler task to run `rake fetch:all` every 10 minutes.

Once configured, the application generates images via Scheduler, which means that sleeping `Free` dynos are no issue.

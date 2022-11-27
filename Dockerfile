FROM ruby:3.0.5-alpine

RUN apk add --update build-base postgresql-dev tzdata git
RUN gem install rails -v '7.0.0'

WORKDIR /app
ADD Gemfile Gemfile.lock /app/
RUN bundle install

ADD . .
CMD ["puma"]